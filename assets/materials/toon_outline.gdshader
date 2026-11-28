// DARTSTORM v2.0.0 Stylized Warm-Navy Comic Ink Outline (Inverted Hull)
// Distance-adaptive silhouette extrusion that keeps crisp comic line weight in
// first-person and mid-range arena play, then fades smoothly at long distance.
shader_type spatial;
render_mode cull_front, unshaded, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.039, 0.094, 0.239, 1.0);
uniform float outline_width : hint_range(0.0, 0.05) = 0.009;
uniform float distance_scale : hint_range(0.0, 0.02) = 0.0022;
uniform float fade_start : hint_range(5.0, 100.0) = 32.0;
uniform float fade_end : hint_range(10.0, 150.0) = 56.0;

void vertex() {
	vec3 view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float cam_dist = length(view_pos);
	float dist_fade = 1.0 - smoothstep(fade_start, fade_end, cam_dist);
	float thickness = clamp(outline_width + cam_dist * distance_scale, 0.0, outline_width * 2.2) * dist_fade;
	VERTEX += normalize(NORMAL) * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
