// AAA Stylized Timber Planks: Warm cartoon wood with procedural board striations, normal relief and ORM response.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 wood_tint : source_color = vec4(0.74, 0.54, 0.34, 1.0);
uniform float plank_scale : hint_range(0.2, 5.0) = 1.2;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.12;
uniform float roughness : hint_range(0.0, 1.0) = 0.72;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.3;

uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_orm : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(0.0, 2.0) = 0.8;

varying vec3 v_world_pos;
varying vec3 v_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Pick coordinates along dominant plane
	vec3 n = abs(v_normal);
	vec2 uv_proj;
	if (n.y > n.x && n.y > n.z) {
		uv_proj = v_world_pos.xz * plank_scale;
	} else if (n.x > n.z) {
		uv_proj = v_world_pos.yz * plank_scale;
	} else {
		uv_proj = v_world_pos.xy * plank_scale;
	}

	// Procedural plank lines and subtle wavy grain
	float plank = sin(uv_proj.y * 3.14159);
	float grain = sin(uv_proj.y * 16.0 + sin(uv_proj.x * 4.0) * 1.5) * 0.5 + 0.5;
	float plank_seam = smoothstep(0.85, 0.98, abs(plank));

	vec3 col = wood_tint.rgb;
	col = mix(col, col * 0.75, plank_seam * 0.45);
	col += (grain - 0.5) * grain_strength * col;

	// PBR textures
	vec3 n_sample = texture(texture_normal, uv_proj).rgb;
	vec3 orm_sample = texture(texture_orm, uv_proj).rgb;

	NORMAL_MAP = n_sample;
	NORMAL_MAP_DEPTH = normal_scale;

	AO = orm_sample.r;
	AO_LIGHT_AFFECT = 0.6;

	ALBEDO = col;
	ROUGHNESS = mix(roughness, orm_sample.g, 0.45) + (1.0 - grain) * 0.05;
	METALLIC = orm_sample.b;
	SPECULAR = 0.28;

	// Soft cartoon edge rim
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	RIM = fresnel * rim_strength;
	RIM_TINT = 0.4;
}
