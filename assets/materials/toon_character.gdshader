// DARTSTORM Stylized Cartoon Cel-Shader (v2.0.0 Cover-Art Chromatic Cel Upgrade)
// Features:
// - 3-band chromatic cel ramp with warm hue-shifted shadows (zero muddy black undersides)
// - Glossy jelly-bean catchlight specular & sunlit golden rim silhouette highlights
// - Vertex-color baked AO support + optional fabric/rubber normal map texture detail
// - Live combat & elemental status visuals: hit_flash, frost_amount, fire_glow, wet_gloss, electric_arc
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_albedo_texture = false;
uniform bool use_vertex_color = false;
uniform vec4 shadow_tint : source_color = vec4(0.28, 0.26, 0.56, 1.0);
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.42;
uniform vec4 rim_color : source_color = vec4(1.0, 0.96, 0.86, 1.0);
uniform float rim_width : hint_range(0.05, 0.95) = 0.44;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.58;
uniform float roughness : hint_range(0.0, 1.0) = 0.68;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular_strength : hint_range(0.0, 1.5) = 0.34;

uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(0.0, 2.0) = 0.35;
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
	if (use_vertex_color) {
		base_col *= mix(vec3(1.0), v_vcol, 0.85);
	}
	float rough = roughness;
	float met = metallic;
	vec3 emissive = base_col * 0.04;

	if (use_normal_map) {
		NORMAL_MAP = texture(texture_normal, UV * 3.0).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}

	// Wet soaked sheen
	if (wet_gloss > 0.01) {
		base_col = mix(base_col, base_col * 0.84 + vec3(0.02, 0.08, 0.16), wet_gloss * 0.45);
		rough = mix(rough, 0.16, wet_gloss);
	}

	// Frost ice crystal glaze
	if (frost_amount > 0.01) {
		float crystal = sin(v_world_pos.x * 18.0) * cos(v_world_pos.y * 18.0) * sin(v_world_pos.z * 18.0) * 0.5 + 0.5;
		vec3 ice_col = mix(vec3(0.62, 0.90, 1.0), vec3(0.92, 0.99, 1.0), crystal);
		base_col = mix(base_col, ice_col, frost_amount * 0.62);
		rough = mix(rough, 0.20, frost_amount);
		emissive += vec3(0.28, 0.72, 1.0) * frost_amount * (0.25 + crystal * 0.35);
	}

	// Stylized Fresnel Rim Lighting
	float v_dot_n = clamp(dot(normalize(VIEW), normalize(NORMAL)), 0.0, 1.0);
	float fresnel = 1.0 - v_dot_n;
	float rim = smoothstep(1.0 - rim_width, 1.0, fresnel) * rim_strength;

	vec3 active_rim_col = rim_color.rgb;

	// Fire sparkle ember rim
	if (fire_glow > 0.01) {
		float flicker = 0.65 + 0.35 * sin(TIME * 14.0 + v_world_pos.y * 12.0);
		active_rim_col = mix(active_rim_col, vec3(1.0, 0.48, 0.10), fire_glow);
		emissive += vec3(1.0, 0.42, 0.08) * fire_glow * (0.30 + fresnel * 1.15) * flicker;
	}

	// Electric lightning zap crackle
	if (electric_arc > 0.01) {
		float zap = step(0.55, abs(sin(TIME * 32.0 + v_world_pos.y * 22.0 + v_world_pos.x * 14.0)));
		emissive += vec3(1.0, 0.95, 0.30) * electric_arc * (0.35 + zap * 1.4);
	}

	// Crisp impact hit flash
	if (hit_flash > 0.01) {
		base_col = mix(base_col, vec3(1.0, 0.98, 0.94), hit_flash * 0.85);
		emissive += vec3(1.0, 0.96, 0.88) * hit_flash * 1.35;
	}

	ALBEDO = base_col;
	ROUGHNESS = rough;
	METALLIC = met;
	EMISSION = emissive + active_rim_col * (rim * 0.16);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit_val = ndl * 0.5 + 0.5;
	float att = smoothstep(0.15, 0.65, ATTENUATION);

	// 3-band Pixar/Splatoon chromatic cel ramp
	float band_mid = smoothstep(0.35, 0.46, lit_val);
	float band_hi = smoothstep(0.64, 0.75, lit_val);
	float cel = mix(0.38, mix(0.76, 1.02, band_hi), band_mid);
	cel = mix(0.40, cel, att);

	vec3 shadow_col = ALBEDO * mix(vec3(1.0), shadow_tint.rgb * 1.72, shadow_strength);
	vec3 tinted = mix(shadow_col, ALBEDO, smoothstep(0.38, 0.82, cel));
	DIFFUSE_LIGHT += tinted * LIGHT_COLOR * (cel / PI);

	// Soft stylized specular + sunlit edge rim
	vec3 half_vec = normalize(LIGHT + VIEW);
	float ndh = max(dot(NORMAL, half_vec), 0.0);
	float spec_thresh = clamp(0.84 + ROUGHNESS * 0.11, 0.80, 0.96);
	float spec = smoothstep(spec_thresh, min(spec_thresh + 0.04, 0.995), ndh);
	SPECULAR_LIGHT += LIGHT_COLOR * spec * specular_strength * (1.1 - ROUGHNESS * 0.65) * att * band_mid * 0.40;

	float rim_mask = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.6);
	float sun_rim = smoothstep(0.40, 0.76, rim_mask) * smoothstep(0.25, 0.65, lit_val) * att;
	SPECULAR_LIGHT += rim_color.rgb * LIGHT_COLOR * sun_rim * rim_strength * 0.26;
}
