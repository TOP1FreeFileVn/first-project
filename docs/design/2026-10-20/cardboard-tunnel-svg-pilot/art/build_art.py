"""Build aligned vector layers for the isolated cardboard cat tunnel pilot."""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
HEADER = '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="240" viewBox="0 0 256 240">'
OUTER = ('M28 216 V124 C28 99 32 69 41 51 Q44 44 51 49 L78 74 '
         'Q126 64 175 74 L198 51 Q205 46 209 55 C216 77 220 99 220 124 '
         'V216 Q220 224 212 224 H36 Q28 224 28 216 Z')
OPENING = ('M70 157 C70 122 94 96 128 96 C162 96 186 122 186 157 '
           'V193 C186 207 179 214 165 214 H91 C77 214 70 207 70 193 Z')
OPEN_ENTRY = ('M70 240 V157 C70 122 94 96 128 96 '
              'C162 96 186 122 186 157 V240 Z')
FRONT_OUTLINE = ('M28 216 V124 C28 99 32 69 41 51 Q44 44 51 49 L78 74 '
                 'Q126 64 175 74 L198 51 Q205 46 209 55 C216 77 220 99 220 124 '
                 'V216 Q220 224 212 224 H186 V157 C186 122 162 96 128 96 '
                 'C94 96 70 122 70 157 V224 H36 Q28 224 28 216 Z')

SHADOW = '''<g id="shadow">
  <ellipse cx="130" cy="228" rx="108" ry="9" fill="#583f21" opacity="0.14"/>
</g>'''

# The front panel owns the shared seam. Only the exposed right/back edge is
# outlined here, avoiding a doubled dark seam when the front layer is stacked.
REAR = '''<g id="rear" stroke-linecap="round" stroke-linejoin="round">
  <path d="M202 51 L235 63 Q242 66 242 75 V201 Q242 209 235 213 L215 223
           L216 121 C216 91 211 66 202 51 Z" fill="#d3a15f"/>
  <path d="M202 51 L235 63 Q242 66 242 75 V201 Q242 209 235 213 L215 223"
        fill="none" stroke="#583f21" stroke-width="5"/>
  <path d="M224 80 L236 84 V106 L225 102 Z" fill="#fff0be"/>
  <path d="M230 119 V177" fill="none" stroke="#a57a48" stroke-width="2.5"/>
  <path d="M224 199 L235 194" fill="none" stroke="#a57a48" stroke-width="2.5"/>
</g>'''

INTERIOR = f'''<defs>
  <clipPath id="opening-clip"><path d="{OPENING}"/></clipPath>
</defs>
<g id="interior" clip-path="url(#opening-clip)">
  <path d="{OPENING}" fill="#79582f"/>
  <path d="M70 106 L87 113 V190 L70 207 Z" fill="#694b28"/>
  <path d="M70 204 L87 188 H172 L186 204 V222 H70 Z" fill="#b88e54"/>
  <path d="M87 188 H172" fill="none" stroke="#9b713e" stroke-width="2.5"
        stroke-linecap="round"/>
</g>'''

FRONT = f'''<g id="front" stroke-linecap="round" stroke-linejoin="round">
  <!-- One U-shaped contour opens to ground. No closed sill crosses the actor. -->
  <path d="{FRONT_OUTLINE}" fill="#e9bd7a"
        stroke="#583f21" stroke-width="5"/>
  <path d="M39 91 Q41 68 46 58 L67 78 Z" fill="#d8a762"/>
  <path d="M185 78 L202 60 Q208 78 210 94 Z" fill="#d8a762"/>
  <path d="M79 79 Q125 69 173 79" fill="none" stroke="#b58950" stroke-width="2.5"/>
  <path d="M33 151 L48 151 L47 156 L50 160 L47 165 L50 169 L47 174 L33 174 Z"
        fill="#fff0be"/>
  <path d="M34 158 H44 M34 167 H44" fill="none" stroke="#d5b77b" stroke-width="2"/>
  <path d="M52 194 V209 H64" fill="none" stroke="#b58950" stroke-width="2.5"/>
  <path d="M198 151 V175" fill="none" stroke="#b58950" stroke-width="2.5"/>
</g>'''

for name, body in {"shadow": SHADOW, "rear": REAR, "interior": INTERIOR,
                   "front": FRONT, "source": SHADOW + REAR + INTERIOR + FRONT}.items():
    (HERE / f"{name}.svg").write_text(HEADER + "\n" + body + "\n</svg>\n", encoding="utf-8")

geometry = {
    "status": "isolated_vector_pilot_not_production_approval",
    "canvas": [256, 240],
    "ground_registration": [128, 224],
    "image_offset_from_ground": [-128, -224],
    "layers_back_to_front": ["shadow.svg", "rear.svg", "interior.svg", "front.svg"],
    "opening": {
        "path": OPEN_ENTRY,
        "geometric_bounds": [70, 96, 186, 240],
        "entry_at_ground": True,
        "horizontal_bottom_stroke": False,
        "interior_floor_path_unchanged": OPENING,
        "max_clear_width_after_5px_stroke": 111,
        "raster_clearance_report": "qa.json",
        "front_alpha_is_true": True
    },
    "anchors": {
        "approach_feet": [128, 236],
        "threshold_feet": [128, 212],
        "inside_rest_feet": [128, 202],
        "deep_feet": [128, 188]
    },
    "front_outline": FRONT_OUTLINE,
    "scale_reference": {
        "prop_canvas_width_world": 220,
        "cat_canvas_width_world": 90,
        "prop_main_stroke_world": 4.296875,
        "cat_main_stroke_world": 4.21875,
        "max_clear_opening_world": 95.390625,
        "cat_painted_width_world_approx": 72
    },
    "stroke": {"main": 5, "secondary": 2.5, "tape_marks": 2,
               "main_color": "#583f21", "secondary_color": "#b58950"},
    "occlusion_rule": "Use rear/interior, actor, front only while actor is assigned to the doorway/inside zone. Outside actors remain foot-sorted with the whole prop.",
    "cat_not_embedded": True
}
(HERE / "geometry.json").write_text(json.dumps(geometry, indent=2) + "\n", encoding="utf-8")
print("Built 5 SVG layers and geometry.json in", HERE)
