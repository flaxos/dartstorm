// DARTSTORM Cartoon Foam Lava Shader (1.0 Overhaul)
// Molten bubbling orange foam with incandescent neon seams, rolling waves,
// boiling micro-bubbles, and true depth-tested contact foam rims (Forward+ & Compatibility safe).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 lava_color_hot : source_color = vec4(1.0, 0.95, 0.35, 1.0);
uniform vec4 lava_color_molten : source_color = vec4(1.0, 0.40, 0.04, 1.0);
uniform vec4 lava_color_crust : source_color = vec4(0.24, 0.09, 0.05, 1.0);
uniform float world_scale : hint_range(0.05, 2.0) = 0.35;
uniform float flow_speed : hint_range(0.05, 2.0) = 0.30;
uniform float emission_energy : hint_range(0.5, 6.0) = 2.6;
uniform float wave_height : hint_range(0.0, 0.4) = 0.12;
uniform float foam_rim_width : hint_range(0.05, 1.5) = 0.42;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

varying vec3 v_world_pos;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float voronoi(vec2 x, float time) {
	vec2 n = floor(x);
	vec2 f = fract(x);
	float m_dist = 1.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash2(n + g);
			vec2 delta = g + o + sin(time + 6.2831853 * o) * 0.28 - f;
			float d = length(delta);
			m_dist = min(m_dist, d);
		}
	}
	return m_dist;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wave1 = sin(TIME * 2.2 + v_world_pos.x * 0.38) * cos(TIME * 1.8 + v_world_pos.z * 0.38);
	float wave2 = sin(TIME * 3.1 + (v_world_pos.x + v_world_pos.z) * 0.6) * 0.35;
	VERTEX.y += (wave1 + wave2) * wave_height;
}

void fragment() {
	vec2 coord = v_world_pos.xz * world_scale;
	vec2 flow1 = vec2(sin(TIME * flow_speed * 0.8), cos(TIME * flow_speed * 0.7)) * 0.14;
	vec2 flow2 = vec2(-cos(TIME * flow_speed * 0.6), sin(TIME * flow_speed * 0.9)) * 0.11;

	float v1 = voronoi(coord + flow1, TIME * 1.5);
	float v2 = voronoi(coord * 1.75 + flow2, TIME * 2.1);

	float seam = 1.0 - smoothstep(0.04, 0.30, v1);
	float micro_bubble = 1.0 - smoothstep(0.03, 0.20, v2);
	float crust = smoothstep(0.42, 0.80, v1 * 0.65 + v2 * 0.35);

	vec3 molten = mix(lava_color_molten.rgb, lava_color_hot.rgb, clamp(seam + micro_bubble * 0.55, 0.0, 1.0));
	vec3 col = mix(molten, lava_color_crust.rgb, crust);

	// True contact foam rim against opaque walls/ramps (renders in transparent pass so depth_texture holds scene behind lava)
	float depth_raw = texture(depth_texture, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw * 2.0 - 1.0);
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
#endif
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= max(abs(view_pos.w), 0.0001) * sign(view_pos.w + 0.00001);
	float linear_depth = -view_pos.z;
	float surface_depth = -VERTEX.z;
	float depth_diff = linear_depth - surface_depth;
	float foam_rim = 0.0;
	if (depth_diff >= 0.0 && depth_diff < foam_rim_width) {
		foam_rim = pow(1.0 - clamp(depth_diff / max(foam_rim_width, 0.01), 0.0, 1.0), 1.7);
	}

	col = mix(col, lava_color_hot.rgb * 1.15, foam_rim * 0.85);

	ALBEDO = col;
	ALPHA = 0.99;
	ROUGHNESS = mix(0.20, 0.86, crust);
	METALLIC = 0.05;
	SPECULAR = mix(0.75, 0.2, crust);

	vec3 emissive_glow = mix(lava_color_hot.rgb * emission_energy, vec3(0.0), crust * 0.88);
	emissive_glow += lava_color_hot.rgb * (foam_rim * 2.8);
	EMISSION = emissive_glow;
}
