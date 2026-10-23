shader_type canvas_item;

// Reuse the category silhouettes in white while preserving parent UI fades.
// Their original grey artwork remains unchanged for empty equipment slots.
varying vec4 canvas_tint;

void vertex() {
	canvas_tint = COLOR;
}

void fragment() {
	COLOR = vec4(vec3(1.0), texture(TEXTURE, UV).a) * canvas_tint;
}
