// DARTSTORM Blaster Skin Shader
// High-tactile PBR spatial shader with sharp object-space tri-planar pattern mapping.
// Eliminates UV stretching on procedural CSG box/cylinder meshes with 0 AI baked shadows.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 body_color : source_color = vec4(0.15, 0.45, 1.0, 1.0);
uniform vec4 accent_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
uniform sampler2D skin_pattern : source_color, filter_linear_mipmap, repeat_enable;
uniform float pattern_scale : hint_range(0.1, 40.0) = 18.0;
uniform float pattern_blend_power : hint_range(1.0, 32.0) = 12.0;

// 0: MATTE, 1: GLOSS, 2: METALLIC_FLAKE, 3: HOLOGRAPHIC_IRIDESCENT
uniform int finish_mode : hint_range(0, 3) = 1;
uniform float roughness : hint_range(0.0, 1.0) = 0.25;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.4;
uniform float pattern_intensity : hint_range(0.0, 1.0) = 0.92;

varying vec3 v_obj_pos;
varying vec3 v_obj_normal;

void vertex() {
	v_obj_pos = VERTEX;
	v_obj_normal = normalize(NORMAL);
}

void fragment() {
	// Sharp object-space tri-planar blending to prevent seam stretching on CSG meshes
	vec3 blend_weights = pow(abs(v_obj_normal), vec3(pattern_blend_power));
	blend_weights /= max(blend_weights.x + blend_weights.y + blend_weights.z, 0.0001);

	vec2 uv_x = v_obj_pos.zy * pattern_scale;
	vec2 uv_y = v_obj_pos.xz * pattern_scale;
	vec2 uv_z = v_obj_pos.xy * pattern_scale;

	vec4 col_x = texture(skin_pattern, uv_x);
	vec4 col_y = texture(skin_pattern, uv_y);
	vec4 col_z = texture(skin_pattern, uv_z);

	vec4 pattern = col_x * blend_weights.x + col_y * blend_weights.y + col_z * blend_weights.z;

	// Vibrant sticker decal overlay on top of molded body color
	vec3 base_albedo = mix(body_color.rgb, pattern.rgb, pattern_intensity);

	ALBEDO = base_albedo;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = 0.55;

	// Finish Mode Styling
	if (finish_mode == 0) {
		// Matte Toy Plastic
		ROUGHNESS = 0.72;
		METALLIC = 0.0;
	} else if (finish_mode == 1) {
		// High-Gloss Molded Vinyl
		ROUGHNESS = 0.22;
		METALLIC = 0.05;
		SPECULAR = 0.65;
	} else if (finish_mode == 2) {
		// Metallic Foil Flake
		ROUGHNESS = 0.28;
		METALLIC = 0.75;
		SPECULAR = 0.85;
	} else if (finish_mode == 3) {
		// Holographic Iridescent Foil: rainbow shift across view angle
		float view_angle = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float hue = fract(view_angle * 1.6 + pattern.g * 0.35);
		vec3 rainbow = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
		ALBEDO = mix(base_albedo, rainbow, 0.52);
		ROUGHNESS = 0.18;
		METALLIC = 0.45;
		SPECULAR = 0.95;
	}

	// Molded plastic tactile Fresnel rim
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	RIM = fresnel * rim_strength;
	RIM_TINT = 0.5;
}
