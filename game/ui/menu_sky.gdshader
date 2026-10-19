shader_type canvas_item;

// All page overlays sample the same screen-space scene and animation clock.
uniform sampler2D sky_scene : source_color, filter_linear;
uniform sampler2D clouds_far : source_color, filter_linear;
uniform sampler2D clouds_near : source_color, filter_linear;
uniform sampler2D clouds_front : source_color, filter_linear;
uniform sampler2D distant_islands : source_color, filter_linear;
uniform float motion_speed = 1.0;
uniform float time_offset = 0.0;

// Extra canvas preserves the complete shapes that start outside the screen.
vec2 layer_uv(vec2 screen_uv, vec2 offset_px) {
	return (screen_uv * vec2(720.0, 1280.0) + vec2(160.0, 96.0) - offset_px) / vec2(1040.0, 1472.0);
}

void fragment() {
	float t = TIME * motion_speed + time_offset;
	vec2 far_offset = vec2(18.0 * sin(t * 0.17), 3.0 * sin(t * 0.14));
	vec2 near_offset = vec2(34.0 * sin(t * 0.18), 6.0 * sin(t * 0.18));
	vec2 front_offset = vec2(48.0 * sin(t * 0.15), 8.0 * sin(t * 0.16));
	vec2 island_offset = vec2(3.0 * sin(t * 0.12), 5.0 * sin(t * 0.45));
	vec3 scene = texture(sky_scene, SCREEN_UV).rgb;
	vec4 far_cloud = texture(clouds_far, layer_uv(SCREEN_UV, far_offset));
	vec4 islands = texture(distant_islands, layer_uv(SCREEN_UV, island_offset));
	vec4 near_cloud = texture(clouds_near, layer_uv(SCREEN_UV, near_offset));
	vec4 front_cloud = texture(clouds_front, layer_uv(SCREEN_UV, front_offset));
	scene = mix(scene, far_cloud.rgb, far_cloud.a);
	scene = mix(scene, islands.rgb, islands.a);
	scene = mix(scene, near_cloud.rgb, near_cloud.a);
	scene = mix(scene, front_cloud.rgb, front_cloud.a);
	COLOR = vec4(scene, 1.0);
}
