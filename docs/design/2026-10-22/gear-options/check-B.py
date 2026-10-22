"""Read-only NumPy translation of PinMeshTest geometry for proposal SVGs."""
import argparse
import json
import math
import re
from pathlib import Path

import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument("svg", nargs="?", default=str(Path(__file__).parent / "svg/B.svg"))
parser.add_argument("--fit", type=float, default=1.0)
parser.add_argument("--profile", nargs=4, type=float, metavar=('ROOT', 'SHOULDER', 'CAP_ANGLE', 'CORNER'))
parser.add_argument("--shoulder-angle", type=float, default=16)
args = parser.parse_args()
match = re.search(r'<path\s+d="([^"]+)"[^>]*stroke-width="([0-9.]+)"', Path(args.svg).read_text())
tokens = re.findall(r'[A-Za-z]|[-+]?[0-9]+(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?', match[1])
if args.profile:
    root, shoulder, cap_angle, corner_radius = args.profile
    vertices = []
    for i in range(8):
        for angle, radius in [(-22.5, root), (-args.shoulder_angle, shoulder), (-cap_angle, 54), (cap_angle, 54), (args.shoulder_angle, shoulder)]:
            angle = math.radians(angle + i * 45 + 13.5)
            vertices.append(np.array([math.cos(angle), math.sin(angle)]) * radius + 64)
    corners = []
    for i, p in enumerate(vertices):
        a, b = vertices[(i - 1) % len(vertices)], vertices[(i + 1) % len(vertices)]
        la, lb = np.linalg.norm(a - p), np.linalg.norm(b - p)
        d = min(corner_radius, la * .32, lb * .32)
        corners.append((a * 0 + p + (a - p) * d / la, p, p + (b - p) * d / lb))
    tokens = ['M'] + [str(round(float(v), 2)) for v in corners[0][0]]
    for i, (a, p, b) in enumerate(corners):
        if i:
            tokens += ['L'] + [str(round(float(v), 2)) for v in a]
        tokens += ['Q'] + [str(round(float(v), 2)) for v in list(p) + list(b)]
    tokens += ['Z']
points = []
cursor = 0
at = np.zeros(2)
error = 0
steps = 8
while cursor < len(tokens):
    cmd = tokens[cursor]
    cursor += 1
    if cmd in ('M', 'L'):
        at = np.array(list(map(float, tokens[cursor:cursor + 2])))
        cursor += 2
        points.append(at)
    elif cmd == 'Q':
        control = np.array(list(map(float, tokens[cursor:cursor + 2])))
        end = np.array(list(map(float, tokens[cursor + 2:cursor + 4])))
        cursor += 4
        error = max(error, np.linalg.norm(at - 2 * control + end) / (4 * steps * steps))
        for step in range(1, steps + 1):
            t = step / steps
            points.append(at * (1 - t) ** 2 + 2 * control * t * (1 - t) + end * t ** 2)
        at = end
    elif cmd != 'Z':
        raise ValueError(cmd)
points = (np.array(points) - 64) * args.fit
ink = float(match[2]) * args.fit
error *= args.fit
pitch = math.tau / 8
reach = math.sqrt(100 ** 2 + 54 ** 2 - 2 * 100 * 54 * math.cos(math.pi / 8))
entry = math.acos((100 ** 2 + reach ** 2 - 54 ** 2) / (2 * 100 * reach))
edge = math.atan2(reach * math.sin(entry), 100 - reach * math.cos(entry))


def rotate(poly, angle):
    c, s = math.cos(angle), math.sin(angle)
    return poly @ np.array([[c, s], [-s, c]])


def point_dist(point, poly):
    start, end = np.roll(poly, 1, axis=0), poly
    delta = end - start
    t = np.clip(np.sum((point - start) * delta, axis=1) / np.maximum(np.sum(delta * delta, axis=1), 1e-20), 0, 1)
    return np.min(np.linalg.norm(point - (start + t[:, None] * delta), axis=1))


def inside(point, poly):
    a, b = np.roll(poly, 1, axis=0), poly
    x, y = point
    crossed = ((a[:, 1] > y) != (b[:, 1] > y)) & (x < (b[:, 0] - a[:, 0]) * (y - a[:, 1]) / (b[:, 1] - a[:, 1] + 1e-20) + a[:, 0])
    return np.count_nonzero(crossed) % 2 == 1


def cross(a, b):
    return a[..., 0] * b[..., 1] - a[..., 1] * b[..., 0]


def contour_dist(a, b):
    a0, a1 = np.roll(a, 1, axis=0), a
    b0, b1 = np.roll(b, 1, axis=0), b
    ma = np.maximum(a0[:, 0], a1[:, 0]) >= 35
    mb = np.minimum(b0[:, 0], b1[:, 0]) <= 65
    a0, a1, b0, b1 = a0[ma], a1[ma], b0[mb], b1[mb]
    pa, pb = a0[:, None, :], b0[None, :, :]
    da, db = (a1 - a0)[:, None, :], (b1 - b0)[None, :, :]
    divisor = cross(da, db)
    safe = np.where(abs(divisor) > 1e-12, divisor, np.nan)
    ta, tb = cross(pb - pa, db) / safe, cross(pb - pa, da) / safe
    if np.any((ta >= 0) & (ta <= 1) & (tb >= 0) & (tb <= 1)):
        return 0.0

    def endpoints_to_segments(p, start, delta):
        t = np.clip(np.sum((p - start) * delta, axis=2) / np.maximum(np.sum(delta * delta, axis=2), 1e-20), 0, 1)
        return np.min(np.linalg.norm(p - start - t[:, :, None] * delta, axis=2))

    return min(endpoints_to_segments(pa, pb, db), endpoints_to_segments(a1[:, None, :], pb, db),
               endpoints_to_segments(pb, pa, da), endpoints_to_segments(b1[None, :, :], pa, da))


min_pin = (float('inf'), None)
intrusions = 0
for direction in [0, math.pi / 2, math.pi, -math.pi / 2]:
    origin = np.array([math.cos(direction), math.sin(direction)]) * 100
    for i in range(81):
        offset = entry - i * (2 * entry / 80)
        turn = math.atan2(reach * math.sin(offset), 100 - reach * math.cos(offset))
        phase = -.3 * pitch + (edge - turn) / (2 * edge) * pitch
        tip = np.array([math.cos(direction + offset), math.sin(direction + offset)]) * reach - origin
        local = rotate(tip, -phase)
        intrusions += inside(local, points)
        gap = point_dist(local, points) - 3.5 - ink * .5 - error
        if gap < min_pin[0]:
            min_pin = (float(gap), {'direction_deg': math.degrees(direction), 'offset_deg': math.degrees(offset), 'local_tip': local.tolist()})

min_neighbour = (float('inf'), None)
for i in range(121):
    phase = pitch * i / 120
    a = rotate(points, phase)
    b = rotate(points, -phase + .9 * pitch) + np.array([100, 0])
    gap = contour_dist(a, b) - ink - 2 * error
    if gap < min_neighbour[0]:
        min_neighbour = (float(gap), {'phase_deg': math.degrees(phase)})

print(json.dumps({'source': args.svg, 'fit': args.fit, 'profile': args.profile, 'vertices': len(points), 'curve_error': float(error),
                  'stroke': ink, 'pin_reach': reach, 'pin_entry_deg': math.degrees(entry),
                  'min_pin_gap': min_pin, 'pin_centres_inside': int(intrusions), 'min_neighbour_gap': min_neighbour,
                  'passed_geometry': bool(min_pin[0] >= 1.5 and min_neighbour[0] >= .5 and intrusions == 0)}, indent=2))
