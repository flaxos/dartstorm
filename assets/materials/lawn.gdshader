// Freshly mown backyard lawn (1.0 Overhaul):
// Crisp mower stripes, organic value-noise grass tufts (distance-faded to prevent moire),
// drifting sun-wind shadow waves, and soft velvet rim sheen — zero vertex-tilt artifacts.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 color_a : source_color = vec3(0.36, 0.72, 0.28);
uniform vec3 color_b : source_color = vec3(0.28, 0.62, 0.22);
uniform float stripe_width = 4.0;
uniform float tuft_scale = 6.5;
uniform float wind_speed = 1.4;
uniform float wind_strength = 0.035;

varying vec3 world_position;
varying vec3 v_world_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Crisp alternating stadium/backyard mower stripes with gentle organic edge blend
	float stripe_x = smoothstep(0.32, 0.68, sin(world_position.x * 3.14159 / max(stripe_width, 0.5)) * 0.5 + 0.5);
	float stripe_z = smoothstep(0.32, 0.68, sin(world_position.z * 3.14159 / max(stripe_width, 0.5)) * 0.5 + 0.5);
	float stripe = mix(stripe_x, stripe_z, 0.35);

	// Distance-faded multi-octave grass tuft texture (zero mid-range moire)
	float cam_dist = length(VERTEX);
	float detail_fade = 1.0 - smoothstep(14.0, 42.0, cam_dist);
	float macro_patch = value_noise(world_position.xz * 0.16);
	float tuft_coarse = value_noise(world_position.xz * (tuft_scale * 0.35));
	float tuft_fine = value_noise(world_position.xz * tuft_scale);
	float tuft = mix(0.5, mix(tuft_coarse, tuft_fine, 0.55), detail_fade);

	// Sweeping sunlight wind shadow wave across blades
	float wind_wave = value_noise(world_position.xz * 0.12 + vec2(TIME * wind_speed * 0.18, TIME * wind_speed * 0.11));

	float blend_t = clamp(stripe * 0.52 + macro_patch * 0.22 + (tuft - 0.5) * 0.24 + (wind_wave - 0.5) * 0.18, 0.0, 1.0);
	vec3 col = mix(color_a, color_b, blend_t);
	// Warm sunlit blade tips in wind crests
	col += vec3(0.05, 0.06, 0.01) * smoothstep(0.58, 0.90, wind_wave) * (0.4 + detail_fade * 0.6);

	ALBEDO = col;
	ROUGHNESS = mix(0.88, 0.78, stripe * 0.5 + tuft * 0.5);
	SPECULAR = 0.22;

	// Subtle distance-faded normal perturbation on horizontal grass faces
	if (abs(v_world_normal.y) > 0.5 && detail_fade > 0.01) {
		float n_a = value_noise(world_position.xz * tuft_scale + vec2(0.15, 0.0));
		float n_b = value_noise(world_position.xz * tuft_scale + vec2(0.0, 0.15));
		float nx = (n_a - tuft_fine) * 0.45 * detail_fade;
		float nz = (n_b - tuft_fine) * 0.45 * detail_fade;
		vec3 grass_n = normalize(vec3(nx, 1.0, nz));
		NORMAL = normalize((VIEW_MATRIX * vec4(grass_n, 0.0)).xyz);
	}

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.2);
	RIM = fresnel * 0.38;
	RIM_TINT = 0.55;
}
