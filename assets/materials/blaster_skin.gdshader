// DARTSTORM Blaster Skin Shader (1.0 Overhaul)
// Unified model-space triplanar livery, crisp micro-detail PBR, true CLEARCOAT lacquer,
// wired accent_color highlights, metallic flake, prismatic holographic & pulsing emissive finishes.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 body_color : source_color = vec4(0.15, 0.45, 1.0, 1.0);
uniform vec4 accent_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
uniform sampler2D skin_pattern : source_color, filter_linear_mipmap, repeat_enable;
uniform float pattern_scale : hint_range(0.1, 40.0) = 4.5;
uniform float pattern_blend_power : hint_range(1.0, 32.0) = 14.0;

uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_orm : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(0.0, 2.0) = 1.0;
uniform float detail_normal_scale : hint_range(1.0, 64.0) = 16.0;
uniform float detail_normal_blend : hint_range(0.0, 1.0) = 0.38;

// 0: MATTE, 1: GLOSS, 2: METALLIC, 3: HOLOGRAPHIC, 4: ANIMATED_EMISSIVE
uniform int finish_mode : hint_range(0, 4) = 0;
uniform float pattern_intensity : hint_range(0.0, 1.0) = 0.95;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.18;

instance uniform vec3 part_offset = vec3(0.0);
instance uniform vec3 part_rot = vec3(0.0);

varying vec3 v_weapon_pos;
varying vec3 v_weapon_normal;

void vertex() {
	vec3 rad = radians(part_rot);
	float cx = cos(rad.x); float sx = sin(rad.x);
	float cy = cos(rad.y); float sy = sin(rad.y);
	float cz = cos(rad.z); float sz = sin(rad.z);
	mat3 rx = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cx, -sx), vec3(0.0, sx, cx));
	mat3 ry = mat3(vec3(cy, 0.0, sy), vec3(0.0, 1.0, 0.0), vec3(-sy, 0.0, cy));
	mat3 rz = mat3(vec3(cz, -sz, 0.0), vec3(sz, cz, 0.0), vec3(0.0, 0.0, 1.0));
	mat3 rot = rz * ry * rx;

	v_weapon_pos = rot * VERTEX + part_offset;
	v_weapon_normal = normalize(rot * NORMAL);
}

void fragment() {
	vec3 blend_weights = pow(abs(v_weapon_normal), vec3(pattern_blend_power));
	blend_weights /= max(blend_weights.x + blend_weights.y + blend_weights.z, 0.0001);

	vec2 uv_x = v_weapon_pos.zy * pattern_scale;
	vec2 uv_y = v_weapon_pos.xz * pattern_scale;
	vec2 uv_z = v_weapon_pos.xy * pattern_scale;

	vec4 pattern = texture(skin_pattern, uv_x) * blend_weights.x
		+ texture(skin_pattern, uv_y) * blend_weights.y
		+ texture(skin_pattern, uv_z) * blend_weights.z;

	float decal_alpha = clamp(pattern.a * pattern_intensity, 0.0, 1.0);
	// Subtle weapon-identity accent weave at top spine bevels
	float spine_accent = smoothstep(0.88, 0.99, abs(v_weapon_normal.y)) * 0.12;
	vec3 base_albedo = mix(body_color.rgb, accent_color.rgb, spine_accent);
	base_albedo = mix(base_albedo, pattern.rgb, decal_alpha);

	vec3 base_norm = texture(texture_normal, uv_x).rgb * blend_weights.x
		+ texture(texture_normal, uv_y).rgb * blend_weights.y
		+ texture(texture_normal, uv_z).rgb * blend_weights.z;

	vec3 det_norm = texture(texture_detail_normal, v_weapon_pos.zy * detail_normal_scale).rgb * blend_weights.x
		+ texture(texture_detail_normal, v_weapon_pos.xz * detail_normal_scale).rgb * blend_weights.y
		+ texture(texture_detail_normal, v_weapon_pos.xy * detail_normal_scale).rgb * blend_weights.z;

	vec3 n1 = base_norm * 2.0 - 1.0;
	vec3 n2 = det_norm * 2.0 - 1.0;
	vec3 blended_n = normalize(vec3(n1.xy + n2.xy * detail_normal_blend, max(n1.z, 0.15)));
	NORMAL_MAP = blended_n * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_scale;

	vec4 orm = texture(texture_orm, uv_x) * blend_weights.x
		+ texture(texture_orm, uv_y) * blend_weights.y
		+ texture(texture_orm, uv_z) * blend_weights.z;

	AO = orm.r;
	AO_LIGHT_AFFECT = 0.65;

	float base_roughness = mix(orm.g, 0.35, 0.25);
	float base_metallic = orm.b;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);

	ALBEDO = base_albedo;
	ROUGHNESS = base_roughness;
	METALLIC = base_metallic;
	SPECULAR = 0.35;

	if (finish_mode == 0) {
		ROUGHNESS = clamp(orm.g * 1.25, 0.62, 0.92);
		METALLIC = 0.02;
		SPECULAR = 0.28;
	} else if (finish_mode == 1) {
		// High-Gloss Clearcoat Racing Lacquer
		ROUGHNESS = clamp(orm.g * 0.38 + (1.0 - decal_alpha) * 0.06, 0.10, 0.32);
		METALLIC = base_metallic * 0.30;
		SPECULAR = 0.88;
		CLEARCOAT = 0.85;
		CLEARCOAT_ROUGHNESS = 0.08;
	} else if (finish_mode == 2) {
		// Metallic Foil Flake / Brushed Alloy
		ROUGHNESS = clamp(orm.g * 0.52, 0.16, 0.38);
		METALLIC = clamp(max(0.86, base_metallic), 0.0, 1.0);
		SPECULAR = 0.94;
		CLEARCOAT = 0.35;
		CLEARCOAT_ROUGHNESS = 0.16;
	} else if (finish_mode == 3) {
		// Holographic Iridescent Foil
		float view_angle = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float hue = fract(view_angle * 1.85 + pattern.r * 0.4 + v_weapon_pos.z * 1.6);
		vec3 rainbow = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
		ALBEDO = mix(base_albedo, mix(rainbow, accent_color.rgb, 0.18), decal_alpha * 0.68);
		ROUGHNESS = 0.12;
		METALLIC = 0.65;
		SPECULAR = 0.98;
		CLEARCOAT = 0.90;
		CLEARCOAT_ROUGHNESS = 0.06;
	} else if (finish_mode == 4) {
		// Animated Emissive Energy (Cyber Traces, Magma Veins, Bio-Slime)
		float pulse = sin(TIME * 3.8 + v_weapon_pos.z * 14.0) * 0.5 + 0.5;
		float brightness = max(max(pattern.r, pattern.g), pattern.b);
		vec3 glow_color = mix(pattern.rgb, accent_color.rgb, 0.20) * (1.5 + pulse * 1.7);
		EMISSION = glow_color * decal_alpha * smoothstep(0.42, 0.92, brightness);
		ROUGHNESS = 0.20;
		METALLIC = 0.18;
		SPECULAR = 0.72;
	}

	RIM = fresnel * rim_strength;
	RIM_TINT = 0.5;
}
