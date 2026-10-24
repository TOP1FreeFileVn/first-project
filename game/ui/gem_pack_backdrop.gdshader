shader_type canvas_item;
render_mode unshaded;

uniform vec2 rect_size = vec2(192.0, 298.0);
uniform float corner_radius = 13.0;
uniform vec4 top_color : source_color = vec4(0.900, 0.840, 0.970, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.745, 0.590, 0.890, 1.0);
uniform vec4 light_color : source_color = vec4(0.985, 0.955, 1.0, 1.0);
uniform vec4 pedestal_color : source_color = vec4(0.55, 0.37, 0.72, 1.0);

void fragment() {
	vec2 uv = UV;
	// Lilac now reaches the top; the panel itself keeps the narrow cream rim.
	vec3 color = mix(top_color.rgb, bottom_color.rgb, smoothstep(0.0, 0.45, uv.y));
	vec2 light_at = (uv - vec2(0.50, 0.43)) * vec2(1.10, 0.85);
	float halo = exp(-dot(light_at, light_at) * 11.0);
	color = mix(color, light_color.rgb, halo * 0.40);
	// Three broad translucent facets sit behind the illustration, away from text.
	float art_zone = smoothstep(0.16, 0.25, uv.y) * (1.0 - smoothstep(0.72, 0.80, uv.y));
	float left_plane = 1.0 - smoothstep(0.43, 0.45, uv.x + uv.y * 0.45);
	float right_plane = smoothstep(0.58, 0.60, uv.x - uv.y * 0.32);
	float stripe_at = uv.x - uv.y * 0.27;
	float middle_plane = smoothstep(0.17, 0.19, stripe_at) * (1.0 - smoothstep(0.34, 0.36, stripe_at));
	color = mix(color, vec3(1.0), art_zone * (left_plane * 0.18 + right_plane * 0.16 + middle_plane * 0.11));
	// A soft lit pedestal grounds the object without an external panel shadow.
	vec2 oval = (uv - vec2(0.50, 0.715)) / vec2(0.43, 0.045);
	float pedestal = (1.0 - smoothstep(0.70, 1.0, length(oval))) * 0.13;
	color = mix(color, pedestal_color.rgb, pedestal);
	// The inner face stays inside the original cream rim and brown silhouette.
	vec2 q = abs(uv * rect_size - rect_size * 0.5) - (rect_size * 0.5 - vec2(corner_radius));
	float edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	float alpha = 1.0 - smoothstep(-0.6, 0.6, edge);
	COLOR = vec4(color, alpha);
}
