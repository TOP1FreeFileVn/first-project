"""Reproducible aligned SVGs for a low cardboard cat bed pilot."""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
HEADER = '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="240" viewBox="0 0 256 240">'

SHADOW = '''<g id="shadow">
  <ellipse cx="128" cy="228" rx="110" ry="8" fill="#583f21" opacity="0.14"/>
</g>'''

REAR = '''<g id="rear" stroke-linecap="round" stroke-linejoin="round">
  <path d="M24 185 L36 151 Q39 144 48 144 H208 Q217 144 220 152 L232 185
           V212 Q232 224 220 224 H36 Q24 224 24 212 Z" fill="#d3a15f"/>
  <!-- The front parts own the near edges; do not double-stroke their seams. -->
  <path d="M24 185 L36 151 Q39 144 48 144 H208 Q217 144 220 152 L232 185"
        fill="none" stroke="#583f21" stroke-width="5"/>
  <path d="M43 165 H213" fill="none" stroke="#b58950" stroke-width="2.5"/>
  <path d="M115 145 H141 L139 149 L142 153 L139 157 L141 161 H115
           L117 157 L114 153 L117 149 Z" fill="#fff0be"/>
</g>'''

INTERIOR = '''<g id="interior" stroke-linecap="round" stroke-linejoin="round">
  <path d="M25 187 L43 166 H213 L231 187 V213 Q231 224 220 224 H36
           Q25 224 25 213 Z" fill="#e9c68a"/>
  <path d="M53 190 C53 179 76 174 128 174 C180 174 203 179 203 190
           V203 Q203 216 188 216 H68 Q53 216 53 203 Z"
        fill="#fff0be" stroke="#b58950" stroke-width="2.5"/>
  <path d="M113 185 Q128 192 143 185" fill="none" stroke="#d8bc86" stroke-width="2.5"/>
</g>'''

LEFT_FRONT = ('M24 212 V183 L29 164 Q30 161 33 165 L43 179 L69 189 '
              'Q76 192 76 199 V224 H36 Q24 224 24 212 Z')
RIGHT_FRONT = ('M232 212 V183 L227 164 Q226 161 223 165 L213 179 L187 189 '
               'Q180 192 180 199 V224 H220 Q232 224 232 212 Z')

FRONT = f'''<g id="front" stroke-linecap="round" stroke-linejoin="round">
  <!-- Two separate front side walls leave the centre open all the way to ground. -->
  <path d="{LEFT_FRONT}" fill="#e9bd7a" stroke="#583f21" stroke-width="5"/>
  <path d="{RIGHT_FRONT}" fill="#e9bd7a" stroke="#583f21" stroke-width="5"/>
  <path d="M29 184 L32 171 L39 181 Z M227 184 L224 171 L217 181 Z" fill="#d8a762"/>
  <path d="M37 197 V212 H48 M219 197 V212 H208" fill="none"
        stroke="#b58950" stroke-width="2.5"/>
  <path d="M49 188 L62 193" fill="none" stroke="#b58950" stroke-width="2.5"/>
  <path d="M194 193 L207 188" fill="none" stroke="#b58950" stroke-width="2.5"/>
</g>'''

layers = {"shadow": SHADOW, "rear": REAR, "interior": INTERIOR, "front": FRONT}
layers["source"] = "\n".join(layers.values())
for name, body in layers.items():
    (HERE / f"{name}.svg").write_text(HEADER + "\n" + body + "\n</svg>\n", encoding="utf-8")

geometry = {
    "status": "isolated_second_prop_vector_pilot",
    "canvas": [256, 240],
    "ground_registration": [128, 224],
    "image_offset_from_ground": [-128, -224],
    "rear_body_bounds_without_stroke": [24, 144, 232, 224],
    "layers_back_to_front": ["shadow.svg", "rear.svg", "interior.svg", "front.svg"],
    "front_paths": {"left": LEFT_FRONT, "right": RIGHT_FRONT},
    "entry": {
        "centre_x": 128,
        "geometric_x_range": [76, 180],
        "open_to_floor": True,
        "horizontal_sill": False,
        "geometric_ground_clearance": 104,
        "nominal_clearance_after_main_stroke": 99,
        "full_width_entry_y_range": [199, 224],
        "raster_report": "qa.json"
    },
    "anchors": {
        "approach_feet": [128, 238],
        "entry_feet": [128, 224],
        "rest_feet": [128, 210],
        "back_rest_feet": [128, 202]
    },
    "palette": {
        "main_ink": "#583f21", "secondary_ink": "#b58950", "front_cardboard": "#e9bd7a",
        "rear_cardboard": "#d3a15f", "floor": "#e9c68a", "cushion_tape": "#fff0be",
        "ear_fold": "#d8a762", "cushion_detail": "#d8bc86"
    },
    "stroke": {"main": 5, "secondary": 2.5},
    "example_scale": {"prop": 1.18, "native_cat_visual": 0.5,
                      "prop_main_world": 5.9, "cat_main_world": 6,
                      "nominal_entry_world": 116.82},
    "pose_rule": "Cats always display their original front face, including entering and leaving.",
    "occlusion_rule": "Outside: foot-sort whole prop with cat. Enter/rest: rear and interior, cat, front side walls. Do not add a front sill across the centre.",
    "cat_embedded": False
}
(HERE / "geometry.json").write_text(json.dumps(geometry, indent=2) + "\n", encoding="utf-8")
print("Built cardboard bed source, 4 layers and geometry.json")
