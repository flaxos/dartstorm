// DARTSTORM Cartoon Foam Lava Shader
// Molten bubbling orange foam with bright neon seams, rolling waves, and cooling crust patches.
// 100% cartoon aesthetic with zero gore or realistic burn textures.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 lava_color_hot : source_color = vec4(1.0, 0.92, 0.25, 1.0);
uniform vec4 lava_color_molten : source_color = vec4(1.0, 0.38, 0.05, 1.0);
uniform vec4 lava_color_crust : source_color = vec4(0.24, 0.09, 0.04, 1.0);
uniform float bubble_scale : hint_range(0.5, 20.0) = 4.5;
uniform float flow_speed : hint_range(0.05, 2.0) = 0.35;
uniform float emission_energy : hint_range(0.5, 6.0) = 2.4;
uniform float wave_height : hint_range(0.0, 0.3) = 0.08;

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
			vec2 delta = g + o + sin(time + 6.2831853 * o) * 0.25 - f;
			float d = length(delta);
			m_dist = min(m_dist, d);
		}
	}
	return m_dist;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wave = sin(TIME * 2.2 + VERTEX.x * 0.6) * cos(TIME * 1.7 + VERTEX.z * 0.6) * wave_height;
	VERTEX.y += wave;
}

void fragment() {
	vec2 flow = vec2(TIME * flow_speed * 0.15, TIME * flow_speed * 0.1);
	vec2 uv1 = UV * bubble_scale + flow;
	vec2 uv2 = UV * (bubble_scale * 1.6) - flow * 0.8;

	float v1 = voronoi(uv1, TIME * 1.5);
	float v2 = voronoi(uv2, TIME * 2.0);

	// Seam highlights between bubbling foam cells
	float seam = 1.0 - smoothstep(0.05, 0.32, v1);
	// Floating cooling crust islands
	float crust = smoothstep(0.42, 0.82, v1 * 0.6 + v2 * 0.4);

	vec3 col = mix(lava_color_molten.rgb, lava_color_hot.rgb, seam * 0.85);
	col = mix(col, lava_color_crust.rgb, crust);

	ALBEDO = col;
	ROUGHNESS = mix(0.18, 0.88, crust);
	METALLIC = 0.05;
	SPECULAR = 0.5;
	EMISSION = mix(lava_color_hot.rgb * emission_energy, vec3(0.0), crust * 0.9);
}
