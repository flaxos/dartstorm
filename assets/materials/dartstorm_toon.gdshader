// DARTSTORM v2.0.0 Pixar / Fortnite Stylized PBR Master Shader
// Smooth native Burley diffuse + GGX specular + Clearcoat + Subsurface Scattering
// (warm Pixar skin / foliage translucency) + triplanar painterly detail + baked vertex AO
// + full SSAO/SSIL/ReflectionProbe IBL + live combat & elemental status uniforms.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_albedo_texture = false;
uniform bool use_vertex_color = false;
uniform bool use_triplanar = false;
uniform float triplanar_scale : hint_range(0.05, 16.0) = 0.65;

uniform vec4 shadow_tint : source_color = vec4(0.24, 0.28, 0.56, 1.0);
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.25;
uniform float ambient_lift : hint_range(0.0, 0.5) = 0.06;

uniform float roughness : hint_range(0.05, 1.0) = 0.42;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular_strength : hint_range(0.0, 1.5) = 0.48;
uniform float specular_size : hint_range(0.02, 0.6) = 0.16;
uniform float clearcoat_strength : hint_range(0.0, 1.0) = 0.0;
uniform float clearcoat_roughness : hint_range(0.02, 1.0) = 0.14;
uniform float subsurface_strength : hint_range(0.0, 1.0) = 0.0;

uniform vec4 rim_color : source_color = vec4(1.0, 0.96, 0.86, 1.0);
uniform float rim_width : hint_range(0.05, 0.95) = 0.42;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.34;

uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(0.0, 2.0) = 0.55;
uniform float normal_uv_scale : hint_range(0.25, 24.0) = 3.0;
uniform bool use_normal_map = false;

// Live Combat & Elemental Uniforms
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform float frost_amount : hint_range(0.0, 1.0) = 0.0;
uniform float fire_glow : hint_range(0.0, 1.0) = 0.0;
uniform float wet_gloss : hint_range(0.0, 1.0) = 0.0;
uniform float electric_arc : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;
varying vec3 v_world_nrm;
varying vec3 v_vcol;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_vcol = COLOR.rgb;
}

void fragment() {
	vec3 w = pow(abs(v_world_nrm), vec3(6.0));
	w /= max(w.x + w.y + w.z, 0.0001);
	vec2 uv_x = v_world_pos.zy * triplanar_scale;
	vec2 uv_y = v_world_pos.xz * triplanar_scale;
	vec2 uv_z = v_world_pos.xy * triplanar_scale;

	vec3 base_col = albedo_color.rgb;
	if (use_albedo_texture) {
		if (use_triplanar) {
			vec3 tex_c = texture(albedo_texture, uv_x).rgb * w.x
				+ texture(albedo_texture, uv_y).rgb * w.y
				+ texture(albedo_texture, uv_z).rgb * w.z;
			base_col *= tex_c;
		} else {
			base_col *= texture(albedo_texture, UV * normal_uv_scale).rgb;
		}
	}

	float v_ao = 1.0;
	if (use_vertex_color) {
		v_ao = clamp((v_vcol.r + v_vcol.g + v_vcol.b) / 3.0, 0.48, 1.12);
		// Warm sunlit top / gentle chromatic crease AO rather than dull grey darkening
		vec3 ao_tint = mix(shadow_tint.rgb * 1.15 + vec3(0.18), vec3(1.0), clamp((v_ao - 0.55) / 0.45, 0.0, 1.0));
		base_col *= mix(vec3(1.0), v_vcol * mix(vec3(1.0), ao_tint, shadow_strength), 0.82);
	}

	float rough = roughness;
	vec3 emissive = base_col * ambient_lift * 0.12;

	if (use_normal_map) {
		if (use_triplanar) {
			vec3 nx = texture(texture_normal, uv_x).rgb * 2.0 - 1.0;
			vec3 ny = texture(texture_normal, uv_y).rgb * 2.0 - 1.0;
			vec3 nz = texture(texture_normal, uv_z).rgb * 2.0 - 1.0;
			NORMAL_MAP = normalize(nx * w.x + ny * w.y + nz * w.z) * 0.5 + 0.5;
		} else {
			NORMAL_MAP = texture(texture_normal, UV * normal_uv_scale).rgb;
		}
		NORMAL_MAP_DEPTH = normal_scale;
	}

	if (wet_gloss > 0.01) {
		base_col = mix(base_col, base_col * 0.85 + vec3(0.02, 0.09, 0.16), wet_gloss * 0.45);
		rough = mix(rough, 0.12, wet_gloss);
	}

	if (frost_amount > 0.01) {
		float crystal = sin(v_world_pos.x * 18.0) * cos(v_world_pos.y * 18.0) * sin(v_world_pos.z * 18.0) * 0.5 + 0.5;
		vec3 ice_col = mix(vec3(0.62, 0.90, 1.0), vec3(0.94, 0.99, 1.0), crystal);
		base_col = mix(base_col, ice_col, frost_amount * 0.62);
		rough = mix(rough, 0.16, frost_amount);
		emissive += vec3(0.28, 0.72, 1.0) * frost_amount * (0.25 + crystal * 0.35);
	}

	float v_dot_n = clamp(dot(normalize(VIEW), normalize(NORMAL)), 0.0, 1.0);
	float fresnel = pow(1.0 - v_dot_n, 2.6);

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
	ROUGHNESS = clamp(rough, 0.05, 0.98);
	METALLIC = metallic;
	SPECULAR = clamp(specular_strength * 0.65, 0.05, 0.95);
	AO = clamp(v_ao, 0.52, 1.0);
	AO_LIGHT_AFFECT = 0.55;

	if (clearcoat_strength > 0.01) {
		CLEARCOAT = clearcoat_strength;
		CLEARCOAT_ROUGHNESS = clearcoat_roughness;
	}
	if (subsurface_strength > 0.01) {
		SSS_STRENGTH = subsurface_strength;
		BACKLIGHT = base_col * (0.16 * subsurface_strength);
	}

	// Soft golden Pixar silhouette bounce rim (subtle, never harsh flat outlines)
	RIM = clamp(rim_strength * 0.55, 0.0, 0.85);
	RIM_TINT = 0.45;
	EMISSION = emissive + rim_color.rgb * (fresnel * rim_strength * 0.07);
}
