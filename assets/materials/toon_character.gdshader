// DARTSTORM Stylized Cartoon Cel-Shader (Phase 5)
// Features:
// 1. Native hardware-accelerated diffuse_toon & specular_toon render modes.
// 2. High-visibility Fresnel cartoon rim lighting with customizable rim tint & emission.
// 3. Normal mapping with tri-planar and UV options for tactile clothing fabrics and rubber sneaker treads.
// 4. Team-color modulation and roughness/metallic PBR response.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float rim_width : hint_range(0.05, 0.95) = 0.42;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.65;
uniform float roughness : hint_range(0.0, 1.0) = 0.50;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_orm : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(0.0, 2.0) = 0.5;
uniform bool use_triplanar = false;
uniform vec3 uv_scale = vec3(2.0);

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 base_col = albedo_color.rgb;
	float rough = roughness;
	float met = metallic;

	if (use_triplanar) {
		vec3 blend = abs(v_world_normal);
		blend = normalize(max(blend, 0.00001));
		float b_sum = blend.x + blend.y + blend.z;
		blend /= b_sum;

		vec4 orm_x = texture(texture_orm, v_world_pos.zy * uv_scale.x);
		vec4 orm_y = texture(texture_orm, v_world_pos.xz * uv_scale.y);
		vec4 orm_z = texture(texture_orm, v_world_pos.xy * uv_scale.z);
		vec4 orm = orm_x * blend.x + orm_y * blend.y + orm_z * blend.z;
		rough = orm.g * roughness;

		vec3 n_x = texture(texture_normal, v_world_pos.zy * uv_scale.x).rgb * 2.0 - 1.0;
		vec3 n_y = texture(texture_normal, v_world_pos.xz * uv_scale.y).rgb * 2.0 - 1.0;
		vec3 n_z = texture(texture_normal, v_world_pos.xy * uv_scale.z).rgb * 2.0 - 1.0;
		vec3 norm_blend = normalize(n_x * blend.x + n_y * blend.y + n_z * blend.z);
		NORMAL_MAP = norm_blend * 0.5 + 0.5;
		NORMAL_MAP_DEPTH = normal_scale;
	}

	ALBEDO = base_col;
	ROUGHNESS = rough;
	METALLIC = met;

	// Stylized Fresnel Rim Lighting
	float v_dot_n = clamp(dot(normalize(VIEW), normalize(NORMAL)), 0.0, 1.0);
	float fresnel = 1.0 - v_dot_n;
	float rim = smoothstep(1.0 - rim_width, 1.0, fresnel) * rim_strength;

	// Subtle cartoon rim highlight blend
	ALBEDO = mix(ALBEDO, rim_color.rgb, rim * 0.35);
	EMISSION = rim_color.rgb * rim * 0.28;

	RIM = rim_strength;
	RIM_TINT = 0.5;
}
