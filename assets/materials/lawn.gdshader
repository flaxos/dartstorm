// Freshly mown backyard lawn: plush manicured grass with soft mower stripes, wind ripple, blade normal relief and sunlight sheen.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 color_a : source_color = vec3(0.36, 0.72, 0.28);
uniform vec3 color_b : source_color = vec3(0.28, 0.62, 0.22);
uniform float stripe_width = 4.0;
uniform float tuft_scale = 18.0;
uniform float wind_speed = 1.4;
uniform float wind_strength = 0.035;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Gentle animated wind sway on blade surface
	float wind = sin(world_position.x * 0.5 + world_position.z * 0.3 + TIME * wind_speed) * cos(world_position.z * 0.4 - TIME * wind_speed * 0.8);
	VERTEX.y += wind * wind_strength;
}

void fragment() {
	// Soft mower stripes with sine wave blend
	float stripe_x = sin(world_position.x * 3.14159 / stripe_width) * 0.5 + 0.5;
	float stripe_z = sin(world_position.z * 3.14159 / stripe_width) * 0.5 + 0.5;
	float stripe = mix(stripe_x, stripe_z, 0.5);

	// Micro-tuft noise
	float tuft = sin(world_position.x * tuft_scale) * cos(world_position.z * tuft_scale);
	tuft = tuft * 0.5 + 0.5;

	// Animated wind shadow ripples
	float wind_wave = sin(world_position.x * 0.4 + world_position.z * 0.3 + TIME * wind_speed) * 0.5 + 0.5;

	vec3 col = mix(color_a, color_b, stripe * 0.55 + tuft * 0.15 + wind_wave * 0.1);
	ALBEDO = col;
	ROUGHNESS = 0.82;
	SPECULAR = 0.22;

	// Grass blade normal perturbation for plush depth
	float nx = (sin(world_position.x * tuft_scale * 1.5) * 0.5) * 0.18;
	float nz = (cos(world_position.z * tuft_scale * 1.5) * 0.5) * 0.18;
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(vec3(nx, 1.0, nz)), 0.0)).xyz);

	// Velvet grass rim sheen with subsurface scattering appearance
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	RIM = fresnel * 0.45;
	RIM_TINT = 0.6;
}
