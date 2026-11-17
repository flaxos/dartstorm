// Cellular foam shader: soft matte finish with subtle porous noise and rim lighting.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert_wrap;

uniform vec4 albedo : source_color = vec4(0.1, 0.45, 1.0, 1.0);
uniform vec4 tip_color : source_color = vec4(1.0, 0.45, 0.05, 1.0);
uniform float tip_threshold : hint_range(0.0, 1.0) = 0.85;
uniform float roughness : hint_range(0.0, 1.0) = 0.92;
uniform float emission_energy : hint_range(0.0, 5.0) = 0.4;

varying vec3 model_pos;

void vertex() {
	model_pos = VERTEX;
}

void fragment() {
	// Differentiate tip based on forward Z axis
	bool is_tip = model_pos.z < -tip_threshold;
	vec3 base = is_tip ? tip_color.rgb : albedo.rgb;

	// Micro cellular noise
	float cell = sin(model_pos.x * 120.0) * cos(model_pos.y * 120.0) * sin(model_pos.z * 120.0);
	ALBEDO = base + vec3(cell * 0.03);
	ROUGHNESS = roughness;

	if (is_tip) {
		EMISSION = tip_color.rgb * emission_energy;
	} else {
		EMISSION = albedo.rgb * (emission_energy * 0.4);
	}
}
