"""Small NumPy/Pillow helpers for preserving generated equipment geometry.

Work on the already fitted, supersampled item raster.  Give every material a
positive integer label; use ``ink_label`` (normally 0) for source brown ink.
Keep the original object alpha separately: these helpers never redraw its
silhouette.  The caller assigns structural roles and ROIs; color adjacency is
not itself evidence that a line should exist.

Typical use::

    flat = fill_internal_ink(source_labels, object_alpha > 127)
    path = shared_boundary(flat, STEEL, GOLD, roi=band_roi)
    main_ink = round_stroke_mask(path, width=9 * render_scale)

Composite material colors from ``flat`` first, then one mask per selected
shared boundary.  Reapply the separately normalized outer contour.  Do not
retain the old thin seam underneath a newly positioned seam.
"""

from __future__ import annotations

import heapq
import math
from typing import Optional

import numpy as np
from PIL import Image, ImageDraw


_NEIGHBORS = (
    (-1, 0, 1.0), (1, 0, 1.0), (0, -1, 1.0), (0, 1, 1.0),
    (-1, -1, math.sqrt(2)), (-1, 1, math.sqrt(2)),
    (1, -1, math.sqrt(2)), (1, 1, math.sqrt(2)),
)


def _as_2d(value: np.ndarray, name: str) -> np.ndarray:
    a = np.asarray(value)
    if a.ndim != 2:
        raise ValueError(f"{name} must be a two-dimensional raster")
    return a


def fill_internal_ink(
    labels: np.ndarray,
    object_mask: np.ndarray,
    ink_label: int = 0,
    *,
    return_distance: bool = False,
):
    """Fill source ink with the nearest reachable material label.

    Uses multi-source Dijkstra with 8-neighbor distances 1 and sqrt(2).
    This is a constrained grid-geodesic Voronoi fill, not a Euclidean transform
    that can jump across a transparent hole.  Diagonals may not cut a corner
    between two outside pixels.  Known material pixels and everything outside
    ``object_mask`` remain untouched.  Ties choose the smaller material label
    for deterministic results.  Components containing no material seed retain
    their original ink label; the optional distance is infinite there.

    Only ink pixels enter the priority queue, so thin source seams are much
    cheaper than pushing every colored pixel.  The returned label raster has
    int32 dtype.  ``return_distance=True`` returns ``(labels, distance)``.
    """
    src = _as_2d(labels, "labels").astype(np.int32, copy=False)
    domain = _as_2d(object_mask, "object_mask").astype(bool, copy=False)
    if src.shape != domain.shape:
        raise ValueError("labels and object_mask must have matching shapes")
    out = src.copy()
    unknown = domain & (src == ink_label)
    known = domain & ~unknown
    distance = np.full(src.shape, np.inf, dtype=np.float64)
    distance[known] = 0.0
    h, w = src.shape
    queue = []
    eps = 1e-10

    def offer(y, x, candidate_distance, candidate_label):
        previous = distance[y, x]
        if (candidate_distance < previous - eps or
                (abs(candidate_distance - previous) <= eps and
                 candidate_label < out[y, x])):
            distance[y, x] = candidate_distance
            out[y, x] = candidate_label
            heapq.heappush(queue, (candidate_distance, int(candidate_label), y, x))

    # Start only on the material/ink frontier.  All other known pixels already
    # have zero distance and cannot benefit from propagation.
    frontier = np.zeros(src.shape, dtype=bool)
    padded_unknown = np.pad(unknown, 1)
    for dy, dx, _ in _NEIGHBORS:
        frontier |= known & padded_unknown[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
    for y, x in np.argwhere(frontier):
        material = int(src[y, x])
        for dy, dx, cost in _NEIGHBORS:
            ny, nx = y + dy, x + dx
            if not (0 <= ny < h and 0 <= nx < w and unknown[ny, nx]):
                continue
            if dy and dx and not (domain[y, nx] or domain[ny, x]):
                continue
            offer(ny, nx, cost, material)

    while queue:
        d, material, y, x = heapq.heappop(queue)
        if d > distance[y, x] + eps or material != out[y, x]:
            continue
        for dy, dx, cost in _NEIGHBORS:
            ny, nx = y + dy, x + dx
            if not (0 <= ny < h and 0 <= nx < w and unknown[ny, nx]):
                continue
            if dy and dx and not (domain[y, nx] or domain[ny, x]):
                continue
            offer(ny, nx, d + cost, material)
    return (out, distance) if return_distance else out


def thin_zhang_suen(mask: np.ndarray, max_iterations: Optional[int] = None) -> np.ndarray:
    """Return an 8-connected one-pixel skeleton, preserving open endpoints.

    Appropriate for an already selected seam or material boundary.  Do not
    skeletonize the whole artwork ink: exterior contours, shared junctions and
    broad brown material fields must first be separated by role/ROI.
    """
    out = _as_2d(mask, "mask").astype(bool, copy=True)
    limit = max_iterations if max_iterations is not None else sum(out.shape)
    if limit < 1:
        raise ValueError("max_iterations must be positive")
    for _ in range(limit):
        changed = False
        for phase in (0, 1):
            a = np.pad(out, 1)
            p2 = a[:-2, 1:-1]
            p3 = a[:-2, 2:]
            p4 = a[1:-1, 2:]
            p5 = a[2:, 2:]
            p6 = a[2:, 1:-1]
            p7 = a[2:, :-2]
            p8 = a[1:-1, :-2]
            p9 = a[:-2, :-2]
            ring = (p2, p3, p4, p5, p6, p7, p8, p9)
            count = sum(p.astype(np.uint8) for p in ring)
            transitions = sum((~ring[i] & ring[(i + 1) % 8]).astype(np.uint8)
                              for i in range(8))
            remove = out & (count >= 2) & (count <= 6) & (transitions == 1)
            if phase == 0:
                remove &= ~(p2 & p4 & p6) & ~(p4 & p6 & p8)
            else:
                remove &= ~(p2 & p4 & p8) & ~(p2 & p6 & p8)
            if remove.any():
                out[remove] = False
                changed = True
        if not changed:
            return out
    raise RuntimeError("skeleton did not converge within max_iterations")


def shared_boundary(
    filled_labels: np.ndarray,
    label_a: int,
    label_b: int,
    *,
    roi: Optional[np.ndarray] = None,
    object_mask: Optional[np.ndarray] = None,
    thin: bool = True,
) -> np.ndarray:
    """Extract ONE center boundary between two inpainted material labels.

    The boundary is sampled on the A side of a 4-neighbor A/B interface, then
    optionally thinned.  Sampling one side avoids doubled outlines.  The
    unavoidable half-pixel A-side bias is <=0.5/render_scale character pixels;
    use a >=3x fitted raster for main seams.  ``roi`` lets the caller select a
    physical join while omitting a color-only boundary of the same materials.
    Transparent edges are not considered material B and produce no line.
    """
    src = _as_2d(filled_labels, "filled_labels")
    if label_a == label_b:
        raise ValueError("a shared boundary needs two different material labels")
    domain = np.ones(src.shape, bool) if object_mask is None else np.asarray(object_mask, bool)
    if domain.shape != src.shape:
        raise ValueError("object_mask must match filled_labels")
    a, b = (src == label_a) & domain, (src == label_b) & domain
    h, w = src.shape
    p = np.pad(b, 1)
    neighbor_b = (p[:-2, 1:-1] | p[2:, 1:-1] |
                  p[1:-1, :-2] | p[1:-1, 2:])
    boundary = a & neighbor_b
    if roi is not None:
        region = _as_2d(roi, "roi").astype(bool, copy=False)
        if region.shape != src.shape:
            raise ValueError("roi must match filled_labels")
        boundary &= region
    return thin_zhang_suen(boundary) if thin else boundary


def round_stroke_mask(
    centerline: np.ndarray,
    width: float,
    *,
    supersample: int = 4,
    clip_mask: Optional[np.ndarray] = None,
) -> np.ndarray:
    """Rasterize round-capped/round-joined ink; return uint8 alpha [0,255].

    ``width`` is in INPUT raster pixels.  If the item is fitted at 3x and its
    desired line is 9 character pixels, pass 27.  An extra supersampling pass
    provides fractional widths and smooth normals.  Adjacent center pixels are
    connected before round disks are added, so diagonal seams remain continuous.
    Clip only after drawing: clipping a selected seam to its own old thin mask
    would prevent any thickening.  A supplied clip_mask should be the whole
    object or a generously padded role region, never the old source seam.
    """
    path = _as_2d(centerline, "centerline").astype(bool, copy=False)
    if not math.isfinite(width) or width <= 0:
        raise ValueError("width must be positive and finite")
    if not isinstance(supersample, int) or supersample < 1:
        raise ValueError("supersample must be a positive integer")
    h, w = path.shape
    ss = supersample
    target = Image.new("L", (w * ss, h * ss), 0)
    draw = ImageDraw.Draw(target)
    line_width = max(1, round(width * ss))
    # Pixel-center coordinates and W-1 diameter keep an axis-aligned W-pixel
    # stroke at W pixels rather than W+1 with Pillow's inclusive ellipse bounds.
    radius = (line_width - 1) / 2
    forward = ((0, 1), (1, -1), (1, 0), (1, 1))
    for y, x in np.argwhere(path):
        cx, cy = (x + .5) * ss - .5, (y + .5) * ss - .5
        for dy, dx in forward:
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and path[ny, nx]:
                draw.line((cx, cy, (nx + .5) * ss - .5, (ny + .5) * ss - .5),
                          fill=255, width=line_width)
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=255)
    if ss != 1:
        target = target.resize((w, h), Image.Resampling.LANCZOS)
    alpha = np.asarray(target).copy()
    if clip_mask is not None:
        clip = _as_2d(clip_mask, "clip_mask")
        if clip.shape != path.shape:
            raise ValueError("clip_mask must match centerline")
        if clip.dtype == bool:
            alpha[~clip] = 0
        else:
            coverage = np.clip(clip.astype(float), 0, 255)
            if coverage.max(initial=0) <= 1:
                coverage *= 255
            alpha = np.round(alpha.astype(float) * coverage / 255).astype(np.uint8)
    return alpha


if __name__ == "__main__":
    # Check the useful contract: a single straight/curved shared boundary
    # produces one line with the requested optical width, not two outlines.
    domain = np.ones((128, 128), bool)
    labels = np.zeros(domain.shape, np.int32)
    labels[:60] = 1
    labels[65:] = 2
    filled = fill_internal_ink(labels, domain)
    path = shared_boundary(filled, 1, 2, object_mask=domain)
    straight = round_stroke_mask(path, 9)
    straight_width = straight[:, 64].sum() / 255
    assert abs(straight_width - 9) < .4, straight_width
    assert np.count_nonzero(path[:, 64]) == 1

    yy, xx = np.indices(domain.shape)
    radius = np.hypot(xx - 64, yy - 64)
    curved_labels = np.where(radius < 32, 1, np.where(radius > 37, 2, 0))
    curve = shared_boundary(fill_internal_ink(curved_labels, domain), 1, 2)
    curved = round_stroke_mask(curve, 9)
    # A radial cross-section through the right half intersects one seam.
    curved_width = curved[64, 64:].sum() / 255
    assert abs(curved_width - 9) < .65, curved_width

    # Constrained propagation must not carry a label across transparency.
    blocked = np.ones((7, 9), bool)
    blocked[:, 4] = False
    split_labels = np.zeros(blocked.shape, np.int32)
    split_labels[3, 1] = 1
    split_labels[3, 7] = 2
    split = fill_internal_ink(split_labels, blocked)
    assert np.all(split[:, :4] == 1) and np.all(split[:, 5:] == 2)
    assert np.all(split[:, 4] == 0)
    print({"straight_width": round(float(straight_width), 3),
           "curved_normal_width": round(float(curved_width), 3),
           "transparent_barrier": "preserved"})
