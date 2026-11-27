// DARTSTORM Stylized Cartoon Water Shader (1.0 Overhaul)
// Features:
// - True radial puddle coordinates via local XZ + puddle_radius (fixes CylinderMesh UV mapping)
// - Dual-layer animated sunlight caustics & gentle ripple normals
// - Depth absorption gradient & animated shoreline foam ring
// - Glancing Fresnel sky sheen & high-voltage electrified crackle mode
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.32, 0.82, 0.98, 0.72);
uniform vec4 deep_color : source_color = vec4(0.08, 0.42, 0.84, 0.90);
uniform vec4 foam_color : source_color = vec4(0.96, 0.99, 1.0, 0.96);
uniform float puddle_radius : hint_range(0.5, 40.0) = 2.5;
uniform float wave_speed : hint_range(0.1, 5.0) = 1.3;
uniform float wave_frequency : hint_range(0.5, 20.0) = 4.2;
uniform float wave_height : hint_range(0.0, 0.2) = 0.02;
uniform float foam_edge_width : hint_range(0.01, 0.35) = 0.10;
uniform float electrified : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;
varying vec2 v_local_xz;

float caustic_layer(vec2 p, float t) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float min_d = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 h = fract(sin(vec2(dot(i + g, vec2(127.1, 311.7)), dot(i + g, vec2(269.5, 183.3)))) * 43758.5453);
			vec2 offset = 0.5 + 0.35 * sin(t + 6.2831 * h);
			float d = length(g + offset - f);
			min_d = min(min_d, d);
		}
	}
	return pow(clamp(min_d, 0.0, 1.0), 2.2);
}

void vertex() {
	v_local_xz = VERTEX.xz;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w1 = sin(v_world_pos.x * wave_frequency + TIME * wave_speed) * cos(v_world_pos.z * wave_frequency * 0.8 + TIME * wave_speed * 1.2);
	float w2 = sin((v_world_pos.x + v_world_pos.z) * wave_frequency * 0.5 - TIME * wave_speed * 0.8);
	VERTEX.y += (w1 + w2) * wave_height;
}

void fragment() {
	float dist = clamp(length(v_local_xz) / max(puddle_radius, 0.05), 0.0, 1.0);
	float angle = atan(v_local_xz.y, v_local_xz.x);

	// Dual-frequency animated ripple normal
	float t = TIME * wave_speed;
	float n_wave1 = sin(v_world_pos.x * 5.5 + t * 2.1) * cos(v_world_pos.z * 5.5 - t * 1.6);
	float n_wave2 = cos(v_world_pos.x * 11.0 - t * 1.3) * sin(v_world_pos.z * 11.0 + t * 1.8);
	vec3 wave_normal = normalize(vec3((n_wave1 + n_wave2) * 0.14, 1.0, (n_wave1 - n_wave2) * 0.14));
	NORMAL = normalize((VIEW_MATRIX * vec4(wave_normal, 0.0)).xyz);

	// Depth color gradient + crisp sunlit Voronoi caustics
	vec4 water_col = mix(deep_color, shallow_color, smoothstep(0.15, 0.92, dist));
	float caust = caustic_layer(v_world_pos.xz * 1.15 + vec2(t * 0.18, -t * 0.12), t * 1.4);
	water_col.rgb += vec3(0.28, 0.42, 0.50) * smoothstep(0.32, 0.82, caust) * (1.0 - dist * 0.35);

	// Animated bubbly shoreline foam ring
	float edge_wobble = sin(t * 2.8 + angle * 7.0) * 0.025 + cos(t * 1.9 - angle * 4.0) * 0.015;
	float foam = smoothstep(1.0 - foam_edge_width, 1.0, dist + edge_wobble);
	float inner_ring = smoothstep(0.02, 0.0, abs(dist - (0.86 - edge_wobble * 0.8))) * 0.45;
	float total_foam = clamp(foam + inner_ring, 0.0, 1.0);
	vec4 final_col = mix(water_col, foam_color, total_foam * 0.82);

	vec3 emissive = vec3(0.0);
	if (electrified > 0.01) {
		float c1 = sin(t * 24.0 + v_world_pos.x * 20.0 + sin(v_world_pos.z * 9.0) * 2.0);
		float c2 = cos(t * 19.0 + v_world_pos.z * 22.0 - cos(v_world_pos.x * 8.0) * 2.0);
		float crackle = smoothstep(0.55, 0.85, abs(c1 * c2));
		vec3 electric_col = mix(vec3(0.35, 0.92, 1.0), vec3(1.0, 0.98, 0.35), crackle) * 2.6;
		final_col.rgb = mix(final_col.rgb, electric_col, crackle * electrified * 0.85);
		emissive = electric_col * crackle * electrified;
	}

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.6);
	final_col.rgb = mix(final_col.rgb, vec3(0.85, 0.95, 1.0), fresnel * 0.35);

	ALBEDO = final_col.rgb;
	ALPHA = clamp(final_col.a + fresnel * 0.18 + total_foam * 0.15, 0.0, 0.96);
	ROUGHNESS = mix(0.06, 0.42, total_foam);
	METALLIC = 0.08;
	SPECULAR = 0.92;
	EMISSION = emissive;
	RIM = fresnel * 0.55;
	RIM_TINT = 0.25;
}
