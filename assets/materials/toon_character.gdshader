// DARTSTORM v2.0.0 Pixar / Fortnite Stylized PBR Character Shader
// Smooth Burley diffuse + GGX specular + warm subsurface skin scattering (SSS) +
// micro-fabric/denim/hair normal relief + baked vertex AO + live combat/elemental FX.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_albedo_texture = false;
uniform bool use_vertex_color = false;
uniform vec4 shadow_tint : source_color = vec4(0.28, 0.26, 0.52, 1.0);
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.22;
uniform vec4 rim_color : source_color = vec4(1.0, 0.96, 0.86, 1.0);
uniform float rim_width : hint_range(0.05, 0.95) = 0.42;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.36;
uniform float roughness : hint_range(0.0, 1.0) = 0.72;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular_strength : hint_range(0.0, 1.5) = 0.38;
uniform float subsurface_strength : hint_range(0.0, 1.0) = 0.0;
uniform float clearcoat_strength : hint_range(0.0, 1.0) = 0.0;

uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(0.0, 2.0) = 0.45;
uniform float normal_uv_scale : hint_range(0.5, 24.0) = 4.0;
uniform bool use_normal_map = false;

// Dynamic Combat & Elemental Feedback Uniforms
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float frost_amount : hint_range(0.0, 1.0) = 0.0;
uniform float fire_glow : hint_range(0.0, 1.0) = 0.0;
uniform float wet_gloss : hint_range(0.0, 1.0) = 0.0;
uniform float electric_arc : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;
varying vec3 v_vcol;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_vcol = COLOR.rgb;
}

void fragment() {
	vec3 base_col = albedo_color.rgb;
	if (use_albedo_texture) {
		base_col *= texture(albedo_texture, UV).rgb;
	}
	float v_ao = 1.0;
	if (use_vertex_color) {
		v_ao = clamp((v_vcol.r + v_vcol.g + v_vcol.b) / 3.0, 0.50, 1.12);
		base_col *= mix(vec3(1.0), v_vcol, 0.80);
	}
	float rough = roughness;
	float met = metallic;
	vec3 emissive = base_col * 0.025;

	if (use_normal_map) {
		NORMAL_MAP = texture(texture_normal, UV * normal_uv_scale).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}

	if (wet_gloss > 0.01) {
		base_col = mix(base_col, base_col * 0.84 + vec3(0.02, 0.08, 0.16), wet_gloss * 0.45);
		rough = mix(rough, 0.14, wet_gloss);
	}

	if (frost_amount > 0.01) {
		float crystal = sin(v_world_pos.x * 18.0) * cos(v_world_pos.y * 18.0) * sin(v_world_pos.z * 18.0) * 0.5 + 0.5;
		vec3 ice_col = mix(vec3(0.62, 0.90, 1.0), vec3(0.92, 0.99, 1.0), crystal);
		base_col = mix(base_col, ice_col, frost_amount * 0.62);
		rough = mix(rough, 0.18, frost_amount);
		emissive += vec3(0.28, 0.72, 1.0) * frost_amount * (0.25 + crystal * 0.35);
	}

	float v_dot_n = clamp(dot(normalize(VIEW), normalize(NORMAL)), 0.0, 1.0);
	float fresnel = pow(1.0 - v_dot_n, 2.5);

	if (fire_glow > 0.01) {
		float flicker = 0.65 + 0.35 * sin(TIME * 14.0 + v_world_pos.y * 12.0);
		emissive += vec3(1.0, 0.42, 0.08) * fire_glow * (0.30 + fresnel * 1.15) * flicker;
	}

	if (electric_arc > 0.01) {
		float zap = step(0.55, abs(sin(TIME * 32.0 + v_world_pos.y * 22.0 + v_world_pos.x * 14.0)));
		emissive += vec3(1.0, 0.95, 0.30) * electric_arc * (0.35 + zap * 1.4);
	}

	if (hit_flash > 0.01) {
		base_col = mix(base_col, vec3(1.0, 0.98, 0.94), hit_flash * 0.85);
		emissive += vec3(1.0, 0.96, 0.88) * hit_flash * 1.35;
	}

	ALBEDO = base_col;
	ROUGHNESS = clamp(rough, 0.06, 0.96);
	METALLIC = met;
	SPECULAR = clamp(specular_strength * 0.75, 0.08, 0.90);
	AO = clamp(v_ao, 0.55, 1.0);
	AO_LIGHT_AFFECT = 0.55;
	if (subsurface_strength > 0.01) {
		SSS_STRENGTH = subsurface_strength;
		BACKLIGHT = base_col * vec3(1.15, 0.72, 0.58) * (0.22 * subsurface_strength);
	}
	if (clearcoat_strength > 0.01) {
		CLEARCOAT = clearcoat_strength;
		CLEARCOAT_ROUGHNESS = 0.14;
	}
	RIM = clamp(rim_strength * 0.58, 0.0, 0.85);
	RIM_TINT = 0.45;
	EMISSION = emissive + rim_color.rgb * (fresnel * rim_strength * 0.06);
}
