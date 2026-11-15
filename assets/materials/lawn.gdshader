// Freshly mown backyard lawn: a soft two-tone checker in world space.
shader_type spatial;

uniform vec3 color_a : source_color = vec3(0.36, 0.72, 0.28);
uniform vec3 color_b : source_color = vec3(0.30, 0.64, 0.24);
uniform float stripe_width = 4.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float across = step(0.5, fract(world_position.x / (stripe_width * 2.0)));
	float along = step(0.5, fract(world_position.z / (stripe_width * 2.0)));
	ALBEDO = mix(color_a, color_b, abs(across - along));
	ROUGHNESS = 0.95;
}
