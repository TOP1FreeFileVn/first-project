"""Split the accepted sky illustration into transparent animation layers.

The source remains the single-frame reference. Geometry, colours and opacity
are copied unchanged. The base keeps its 720 x 1280 canvas; transparent overlays
have a 160 px horizontal and 96 px vertical overscan so animation does not reveal
cropped cloud edges. Run with ``python tools/ui/split_sky_layers.py``.
"""

from copy import deepcopy
from pathlib import Path
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
SKIN = ROOT / "game" / "ui" / "skin"
SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)


def main() -> None:
    source = ET.parse(SKIN / "bg_sky_islands.svg").getroot()
    tag = lambda name: f"{{{SVG_NS}}}{name}"
    groups = [child for child in source if child.tag == tag("g")]
    clouds = {
        "bg_sky_clouds_far.svg": "#edf1e5",
        "bg_sky_clouds_near.svg": "#e7eee2",
        "bg_sky_clouds_front.svg": "#e9eee0",
    }
    layers = {
        "bg_sky_base.svg": [
            child for child in source if child.tag in (tag("defs"), tag("rect"))
        ],
        **{
            filename: [group for group in groups if group.get("fill") == fill]
            for filename, fill in clouds.items()
        },
        "bg_sky_distant_islands.svg": [
            group for group in groups if group.get("transform") is not None
        ],
    }
    if len(layers["bg_sky_base.svg"]) != 2:
        raise ValueError("Expected one gradient definition and one sky rectangle")
    if any(len(layers[filename]) != 1 for filename in clouds):
        raise ValueError("Expected exactly one group for each accepted cloud layer")
    if len(layers["bg_sky_distant_islands.svg"]) != 3:
        raise ValueError("Expected exactly three distant island groups")
    selected = [element for elements in layers.values() for element in elements]
    if len(selected) != len(source) or len({id(element) for element in selected}) != len(source):
        raise ValueError("Every source element must belong to exactly one layer")

    for filename, elements in layers.items():
        layer = ET.Element(source.tag, source.attrib)
        if filename != "bg_sky_base.svg":
            layer.set("width", "1040")
            layer.set("height", "1472")
            layer.set("viewBox", "-160 -96 1040 1472")
        layer.extend(deepcopy(element) for element in elements)
        ET.indent(layer, space="  ")
        (SKIN / filename).write_text(
            ET.tostring(layer, encoding="unicode") + "\n", encoding="utf-8"
        )
        print(filename)


if __name__ == "__main__":
    main()
