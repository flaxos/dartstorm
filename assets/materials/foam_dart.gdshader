// Cellular EVA foam dart shader (1.0 Overhaul):
// Soft matte porous foam texture with bright silhouette rim and subtle elemental core glow.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert_wrap;

uniform vec4 albedo : source_color = vec4(0.1, 0.45, 1.0, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.88;
uniform float emission_energy : hint_range(0.0, 5.0) = 0.55;

varying vec3 model_pos;

void vertex() {
	model_pos = VERTEX;
}

void fragment() {
	// Fine porous EVA foam grain
	float cell = sin(model_pos.x * 110.0) * cos(model_pos.y * 110.0) * sin(model_pos.z * 110.0);
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.2);
	ALBEDO = albedo.rgb + vec3(cell * 0.035);
	ROUGHNESS = roughness;
	EMISSION = albedo.rgb * (emission_energy * (0.65 + fresnel * 0.9));
}
