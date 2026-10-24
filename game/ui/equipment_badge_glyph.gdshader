shader_type canvas_item;

// Dedicated category glyphs contain solid white bodies and black accent masks.
// Tint only the accent, preserving the authored alpha and parent UI fades.
uniform vec4 accent_color : source_color = vec4(0.46, 0.59, 0.36, 1.0);
varying vec4 canvas_tint;

void vertex() {
	canvas_tint = COLOR;
}

void fragment() {
	vec4 glyph = texture(TEXTURE, UV);
	vec3 fill = mix(accent_color.rgb, vec3(1.0), glyph.r);
	COLOR = vec4(fill, glyph.a) * canvas_tint;
}
