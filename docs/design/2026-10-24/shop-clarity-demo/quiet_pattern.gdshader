shader_type canvas_item;
uniform sampler2D tile : source_color, repeat_enable, filter_linear;
uniform vec4 sky : source_color = vec4(0.204, 0.345, 0.451, 1.0);
uniform float tile_px = 240.0;
uniform vec2 speed = vec2(0.06, 0.035);
varying vec2 local_px;
void vertex() { local_px = VERTEX; }
void fragment() {
	float a = radians(-24.0);
	mat2 turn = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a)));
	vec4 motif = texture(tile, turn * (local_px / tile_px) - TIME * speed);
	vec3 base = mix(sky.rgb * 1.04, sky.rgb * 0.96, clamp(UV.y, 0.0, 1.0));
	COLOR = vec4(mix(base, motif.rgb, motif.a * 0.35), 1.0);
}
