"""Export the approved pirate ship and its rear/front card layers.

The reviewed v2 SVG is the source of truth. Original geometry is copied as text,
without reformatting path data. The rear layer adds only a flat wooden deck
between the approved hull top and near rail, so the cat can stand between layers.
Run from any directory: python docs/design/2026-10-25/cute-pirate-ship/export_layers.py
"""
from pathlib import Path
import re
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[3]
SOURCE = ROOT / "ship-cute-v2.svg"
DESTINATION = PROJECT / "game/ui/art"
OUTER_GROUP = '  <g stroke-linejoin="round" stroke-linecap="round">'
HULL_MARKER = "    <!-- A complete deep hull with a round belly and a high, stepped stern. -->"
CLOSING = "\n  </g>\n</svg>"
SVG_NS = "{http://www.w3.org/2000/svg}"
HULL_TOP = "M68 273 Q130 291 230 291 Q338 291 425 260"
NEAR_RAIL = "M69 273 Q148 303 247 300 Q350 298 425 260"


def reverse_quadratics(path: str) -> str:
    """Reverse a reviewed M/Q-only edge, preserving its control points."""
    tokens = re.findall(r"[MQ]|-?\d+(?:\.\d+)?", path)
    if tokens[0] != "M":
        raise ValueError("Expected a move followed by quadratic rail segments")
    start = (tokens[1], tokens[2])
    segments = []
    position = 3
    while position < len(tokens):
        if tokens[position] != "Q":
            raise ValueError("The reviewed rail needs an updated deck export")
        control = (tokens[position + 1], tokens[position + 2])
        end = (tokens[position + 3], tokens[position + 4])
        segments.append((start, control, end))
        start = end
        position += 5
    # The hull-top edge already ends at the rail's endpoint. Only Q commands
    # are needed to follow the near rail backwards and close the tiny stern gap.
    return " ".join(
        f"Q{control[0]} {control[1]} {start[0]} {start[1]}"
        for start, control, _ in reversed(segments)
    )


def export() -> None:
    approved_bytes = SOURCE.read_bytes()
    source = SOURCE.read_text(encoding="utf-8")
    source_root = ET.fromstring(source)
    if source_root.attrib.get("viewBox") != "0 0 480 420":
        raise ValueError("The approved ship canvas changed; review the card fit")
    paths = list(source_root.iter(SVG_NS + "path"))
    if not any(path.attrib.get("d", "").startswith(HULL_TOP) for path in paths):
        raise ValueError("The approved hull edge changed; review the deck export")
    if not any(path.attrib.get("d") == NEAR_RAIL for path in paths):
        raise ValueError("The approved near rail changed; review the deck export")
    group_start = source.index(OUTER_GROUP) + len(OUTER_GROUP)
    split_at = source.index(HULL_MARKER)
    group_end = source.rindex(CLOSING)
    header = source[:group_start]
    rear_original = source[group_start:split_at].rstrip()
    front_original = source[split_at:group_end].rstrip()
    deck_path = HULL_TOP + " " + reverse_quadratics(NEAR_RAIL) + " Z"
    deck = (
        "\n\n    <!-- Card grounding plane: the same approved hull/rail edges,"
        " one flat wood fill. -->\n"
        f'    <path id="card_deck_plane" d="{deck_path}" '
        'fill="#d7ae78" stroke="none"/>'
    )
    rear = header + rear_original + deck + CLOSING + "\n"
    front = header + "\n" + front_original + CLOSING + "\n"
    # Validate the actual exported XML and layer membership before writing.
    rear_root = ET.fromstring(rear)
    front_root = ET.fromstring(front)
    for exported in (rear_root, front_root):
        if exported.attrib != source_root.attrib:
            raise ValueError("Layer canvas differs from the approved canvas")
    front_paths = list(front_root.iter(SVG_NS + "path"))
    if not front_paths[0].attrib.get("d", "").startswith(HULL_TOP):
        raise ValueError("Foreground must start with the approved hull")
    if any(path.attrib.get("d", "").startswith("M180 310") for path in front_paths):
        raise ValueError("A mast leaked into the foreground layer")
    if not any(path.attrib.get("id") == "card_deck_plane"
               for path in rear_root.iter(SVG_NS + "path")):
        raise ValueError("Rear deck plane is missing")
    DESTINATION.mkdir(parents=True, exist_ok=True)
    (DESTINATION / "pirate_ship.svg").write_bytes(approved_bytes)
    (DESTINATION / "pirate_ship_rear.svg").write_text(rear, encoding="utf-8", newline="\n")
    (DESTINATION / "pirate_ship_front.svg").write_text(front, encoding="utf-8", newline="\n")
    print("PIRATE_SHIP_LAYERS_EXPORTED canvas=480x420 full=approved-v2 rear=rig+deck front=hull")


if __name__ == "__main__":
    export()
