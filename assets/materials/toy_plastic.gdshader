// Stylized toy plastic: glossy molded finish with subtle rim highlights and SSS mimicry.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(0.2, 0.5, 1.0, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.25;
uniform float specular : hint_range(0.0, 1.0) = 0.6;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.35;
uniform float rim_tint : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
	SPECULAR = specular;

	// Tactile Fresnel edge rim for molded plastic sheen
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	RIM = fresnel * rim_strength;
	RIM_TINT = rim_tint;
}
