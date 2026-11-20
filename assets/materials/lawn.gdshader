// Freshly mown backyard lawn: plush manicured grass with soft mower stripes and sunlight sheen.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 color_a : source_color = vec3(0.36, 0.72, 0.28);
uniform vec3 color_b : source_color = vec3(0.28, 0.62, 0.22);
uniform float stripe_width = 4.0;
uniform float tuft_scale = 18.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Soft mower stripes with sine wave blend
	float stripe_x = sin(world_position.x * 3.14159 / stripe_width) * 0.5 + 0.5;
	float stripe_z = sin(world_position.z * 3.14159 / stripe_width) * 0.5 + 0.5;
	float stripe = mix(stripe_x, stripe_z, 0.5);

	// Micro-tuft noise
	float tuft = sin(world_position.x * tuft_scale) * cos(world_position.z * tuft_scale);
	tuft = tuft * 0.5 + 0.5;

	vec3 col = mix(color_a, color_b, stripe * 0.6 + tuft * 0.15);
	ALBEDO = col;
	ROUGHNESS = 0.88;
	SPECULAR = 0.15;

	// Velvet grass rim sheen
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	RIM = fresnel * 0.32;
	RIM_TINT = 0.5;
}
