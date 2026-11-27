// AAA Stylized Timber Planks (1.0 Overhaul):
// Smooth tri-planar projection (zero seam popping), rich warm cedar grain & plank seams,
// blended PBR normal + ORM relief, and soft stylized rim highlight.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 wood_tint : source_color = vec4(0.74, 0.54, 0.34, 1.0);
uniform float plank_scale : hint_range(0.2, 5.0) = 1.2;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.14;
uniform float roughness : hint_range(0.0, 1.0) = 0.72;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.28;

uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_orm : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(0.0, 2.0) = 0.75;

varying vec3 v_world_pos;
varying vec3 v_normal;

float wood_pattern(vec2 uv) {
	float plank = sin(uv.y * 3.14159);
	float seam = smoothstep(0.86, 0.985, abs(plank));
	float grain = sin(uv.y * 15.0 + sin(uv.x * 3.5 + floor(uv.y) * 1.7) * 1.4) * 0.5 + 0.5;
	return mix(grain, 0.0, seam * 0.65);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Smooth power-weighted triplanar projection (eliminates hard plane-switch seams)
	vec3 w = pow(abs(v_normal), vec3(8.0));
	w /= max(w.x + w.y + w.z, 0.0001);

	vec2 uv_x = v_world_pos.zy * plank_scale;
	vec2 uv_y = v_world_pos.xz * plank_scale;
	vec2 uv_z = v_world_pos.xy * plank_scale;

	float pat_x = wood_pattern(uv_x);
	float pat_y = wood_pattern(uv_y);
	float pat_z = wood_pattern(uv_z);
	float pat = pat_x * w.x + pat_y * w.y + pat_z * w.z;

	vec3 col = wood_tint.rgb;
	col = mix(col * 0.74, col * (1.0 + grain_strength), pat);

	// Smooth triplanar ORM & normal blend
	vec3 orm = texture(texture_orm, uv_x).rgb * w.x
		+ texture(texture_orm, uv_y).rgb * w.y
		+ texture(texture_orm, uv_z).rgb * w.z;

	vec3 nx = texture(texture_normal, uv_x).rgb * 2.0 - 1.0;
	vec3 ny = texture(texture_normal, uv_y).rgb * 2.0 - 1.0;
	vec3 nz = texture(texture_normal, uv_z).rgb * 2.0 - 1.0;
	vec3 n_blend = normalize(nx * w.x + ny * w.y + nz * w.z);

	NORMAL_MAP = n_blend * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_scale;

	AO = orm.r;
	AO_LIGHT_AFFECT = 0.6;
	ALBEDO = col;
	ROUGHNESS = mix(roughness, orm.g, 0.45) + (1.0 - pat) * 0.08;
	METALLIC = orm.b * 0.1;
	SPECULAR = 0.28;

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	RIM = fresnel * rim_strength;
	RIM_TINT = 0.4;
}
