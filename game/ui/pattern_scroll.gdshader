shader_type canvas_item;

// Lobby backdrop (Ui.pattern_bg): the sky colour, a soft lighter top, and the bg_tile
// pattern (gears + cat paws, white at low opacity) tilted on a diagonal and drifting
// down-right forever.

uniform sampler2D tile : source_color, repeat_enable, filter_linear;
uniform vec4 sky : source_color = vec4(0.435, 0.639, 0.878, 1.0);
uniform float tile_px = 240.0;
uniform float angle_deg = -24.0;
uniform float pattern_strength = 1.0;
uniform float top_light = 1.08;
uniform float bottom_light = 0.94;
// Tiles per second along the two pattern axes.
uniform vec2 speed = vec2(0.06, 0.035);

varying vec2 local_px;

void vertex() {
	local_px = VERTEX;
}

void fragment() {
	float a = radians(angle_deg);
	mat2 turn = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a)));
	vec2 p = turn * (local_px / tile_px) - TIME * speed;
	vec4 t = texture(tile, p);
	vec3 base = mix(sky.rgb * top_light, sky.rgb * bottom_light, clamp(UV.y, 0.0, 1.0));
	COLOR = vec4(mix(base, t.rgb, t.a * pattern_strength), 1.0);
}
