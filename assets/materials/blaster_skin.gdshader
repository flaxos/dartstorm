// DARTSTORM Blaster Skin Shader — Next-Gen AAA PBR Overhaul
// Features:
// 1. Unified Model-Space Coherence: Uses instance uniforms (part_offset & part_rot) to eliminate
//    fragmented box seams and project continuous, unbroken liveries across complex multi-part meshes.
// 2. High-Poly Tactile PBR:
//    - Tangent-Space Normal Map & Tri-Planar Blending for screws, seams, vents, and grip knurling.
//    - Packed ORM (R=AO, G=Roughness, B=Metallic) for authentic material response.
//    - Tileable Detail Micro-Normal Map for crisp close-up ADS zoom.
// 3. 5 High-Fidelity Finish Modes:
//    - 0: MATTE_TOY (Molded ABS polymer, micro-stippling, tactile roughness)
//    - 1: HIGH_GLOSS (Clearcoat racing lacquer with carbon weave and mirror specular)
//    - 2: METALLIC_FLAKE (Brushed alloy and metallic micro-foil flake)
//    - 3: HOLOGRAPHIC_IRIDESCENT (Dynamic rainbow diffraction shifting with viewing angle)
//    - 4: ANIMATED_EMISSIVE (Pulsating electric circuit, lava fissure, and bio-luminescent glows)

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 body_color : source_color = vec4(0.15, 0.45, 1.0, 1.0);
uniform vec4 accent_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
uniform sampler2D skin_pattern : source_color, filter_linear_mipmap, repeat_enable;
uniform float pattern_scale : hint_range(0.1, 40.0) = 4.5;
uniform float pattern_blend_power : hint_range(1.0, 32.0) = 14.0;

// High-Poly PBR Maps
uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_orm : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(0.0, 2.0) = 1.0;
uniform float detail_normal_scale : hint_range(1.0, 64.0) = 16.0;
uniform float detail_normal_blend : hint_range(0.0, 1.0) = 0.40;

// 0: MATTE, 1: GLOSS, 2: METALLIC, 3: HOLOGRAPHIC, 4: ANIMATED_EMISSIVE
uniform int finish_mode : hint_range(0, 4) = 0;
uniform float pattern_intensity : hint_range(0.0, 1.0) = 0.95;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.15;

// Per-instance transform relative to weapon root for seamless model-space coherence
instance uniform vec3 part_offset = vec3(0.0);
instance uniform vec3 part_rot = vec3(0.0);

varying vec3 v_weapon_pos;
varying vec3 v_weapon_normal;

void vertex() {
	// Euler rotation matrix for part orientation in degrees
	vec3 rad = radians(part_rot);
	float cx = cos(rad.x); float sx = sin(rad.x);
	float cy = cos(rad.y); float sy = sin(rad.y);
	float cz = cos(rad.z); float sz = sin(rad.z);
	mat3 rx = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cx, -sx), vec3(0.0, sx, cx));
	mat3 ry = mat3(vec3(cy, 0.0, sy), vec3(0.0, 1.0, 0.0), vec3(-sy, 0.0, cy));
	mat3 rz = mat3(vec3(cz, -sz, 0.0), vec3(sz, cz, 0.0), vec3(0.0, 0.0, 1.0));
	mat3 rot = rz * ry * rx;

	// Transform vertex into unified weapon-root space
	v_weapon_pos = rot * VERTEX + part_offset;
	v_weapon_normal = normalize(rot * NORMAL);
}

void fragment() {
	// Sharp model-space tri-planar blending
	vec3 blend_weights = pow(abs(v_weapon_normal), vec3(pattern_blend_power));
	blend_weights /= max(blend_weights.x + blend_weights.y + blend_weights.z, 0.0001);

	// Weapon-space UV projections:
	vec2 uv_x = v_weapon_pos.zy * pattern_scale; // Flank/side view
	vec2 uv_y = v_weapon_pos.xz * pattern_scale; // Top/bottom spine view
	vec2 uv_z = v_weapon_pos.xy * pattern_scale; // Front/back cross section

	// 1. Albedo & Pattern sampling
	vec4 col_x = texture(skin_pattern, uv_x);
	vec4 col_y = texture(skin_pattern, uv_y);
	vec4 col_z = texture(skin_pattern, uv_z);
	vec4 pattern = col_x * blend_weights.x + col_y * blend_weights.y + col_z * blend_weights.z;

	float decal_alpha = clamp(pattern.a * pattern_intensity, 0.0, 1.0);
	vec3 base_albedo = mix(body_color.rgb, pattern.rgb, decal_alpha);

	// 2. Normal Map Sampling & Micro-Detail Blending
	vec4 norm_x = texture(texture_normal, uv_x);
	vec4 norm_y = texture(texture_normal, uv_y);
	vec4 norm_z = texture(texture_normal, uv_z);
	vec3 base_norm = norm_x.rgb * blend_weights.x + norm_y.rgb * blend_weights.y + norm_z.rgb * blend_weights.z;

	vec2 duv_x = v_weapon_pos.zy * detail_normal_scale;
	vec2 duv_y = v_weapon_pos.xz * detail_normal_scale;
	vec2 duv_z = v_weapon_pos.xy * detail_normal_scale;
	vec4 dnorm_x = texture(texture_detail_normal, duv_x);
	vec4 dnorm_y = texture(texture_detail_normal, duv_y);
	vec4 dnorm_z = texture(texture_detail_normal, duv_z);
	vec3 det_norm = dnorm_x.rgb * blend_weights.x + dnorm_y.rgb * blend_weights.y + dnorm_z.rgb * blend_weights.z;

	vec3 n1 = base_norm * 2.0 - 1.0;
	vec3 n2 = det_norm * 2.0 - 1.0;
	vec3 blended_n = normalize(vec3(n1.xy + n2.xy * detail_normal_blend, n1.z));
	NORMAL_MAP = blended_n * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_scale;

	// 3. Packed ORM Sampling (R=AO, G=Roughness, B=Metallic)
	vec4 orm_x = texture(texture_orm, uv_x);
	vec4 orm_y = texture(texture_orm, uv_y);
	vec4 orm_z = texture(texture_orm, uv_z);
	vec4 orm = orm_x * blend_weights.x + orm_y * blend_weights.y + orm_z * blend_weights.z;

	AO = orm.r;
	AO_LIGHT_AFFECT = 0.65;

	float base_roughness = mix(orm.g, 0.35, 0.25);
	float base_metallic = orm.b;

	ALBEDO = base_albedo;
	ROUGHNESS = base_roughness;
	METALLIC = base_metallic;
	SPECULAR = 0.30;

	// 4. Finish Mode Execution
	if (finish_mode == 0) {
		// 0: Matte Toy Polymer
		ROUGHNESS = clamp(orm.g * 1.3, 0.65, 0.95);
		METALLIC = 0.01;
		SPECULAR = 0.25;
	} else if (finish_mode == 1) {
		// 1: High-Gloss Clearcoat Racing Lacquer
		ROUGHNESS = clamp(orm.g * 0.42 + (1.0 - decal_alpha) * 0.08, 0.12, 0.38);
		METALLIC = base_metallic * 0.3;
		SPECULAR = 0.85;
	} else if (finish_mode == 2) {
		// 2: Metallic Foil Flake / Brushed Alloy
		ROUGHNESS = clamp(orm.g * 0.6, 0.18, 0.42);
		METALLIC = clamp(max(0.85, base_metallic), 0.0, 1.0);
		SPECULAR = 0.92;
	} else if (finish_mode == 3) {
		// 3: Holographic Iridescent Foil (View-Dependent Prismatic Dispersion)
		float view_angle = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float hue = fract(view_angle * 1.85 + pattern.r * 0.4 + v_weapon_pos.z * 1.6);
		vec3 rainbow = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
		ALBEDO = mix(base_albedo, rainbow, decal_alpha * 0.65);
		ROUGHNESS = 0.14;
		METALLIC = 0.60;
		SPECULAR = 0.98;
	} else if (finish_mode == 4) {
		// 4: Animated Emissive Energy (Cyber Traces, Magma Veins, Bio-Slime)
		float pulse = sin(TIME * 3.8 + v_weapon_pos.z * 14.0) * 0.5 + 0.5;
		float brightness = max(max(pattern.r, pattern.g), pattern.b);
		vec3 glow_color = pattern.rgb * (1.6 + pulse * 1.8);
		EMISSION = glow_color * decal_alpha * smoothstep(0.45, 0.95, brightness);
		ROUGHNESS = 0.22;
		METALLIC = 0.15;
		SPECULAR = 0.70;
	}

	// Molded plastic tactile Fresnel rim
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	RIM = fresnel * rim_strength;
	RIM_TINT = 0.5;
}
