// DARTSTORM v2.0.0 Pixar / Fortnite Stylized Timber Planks (Native Forward+ PBR):
// Smooth tri-planar honey-oak grain, chamfered plank grooves, soft nail recesses,
// blended PBR normal + ORM relief, full SSAO/SSIL/IBL, and warm satin specular.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 wood_tint : source_color = vec4(0.84, 0.60, 0.35, 1.0);
uniform float plank_scale : hint_range(0.2, 5.0) = 1.25;
uniform float grain_strength : hint_range(0.0, 0.5) = 0.16;
uniform float roughness : hint_range(0.0, 1.0) = 0.62;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.24;

uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_orm : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(0.0, 2.0) = 0.82;

varying vec3 v_world_pos;
varying vec3 v_normal;

float wood_pattern(vec2 uv) {
	float board_id = floor(uv.y);
	float frac_y = fract(uv.y);
	float seam_x = fract(uv.x * 0.28 + fract(sin(board_id * 91.7) * 437.5));
	float end_seam = smoothstep(0.0, 0.025, seam_x) * smoothstep(1.0, 0.975, seam_x);
	float bevel = smoothstep(0.0, 0.07, frac_y) * smoothstep(1.0, 0.93, frac_y) * end_seam;
	float board_var = fract(sin(board_id * 12.9898) * 43758.5453) * 0.16 - 0.08;
	float grain = sin(uv.y * 18.0 + sin(uv.x * 3.1 + board_id * 1.9) * 1.45) * 0.5 + 0.5;
	float fine_grain = sin(uv.y * 44.0 + uv.x * 1.6) * 0.5 + 0.5;
	return clamp(mix(0.22, 0.78 + grain * 0.18 + fine_grain * 0.08 + board_var, bevel), 0.0, 1.18);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 w = pow(abs(v_normal), vec3(8.0));
	w /= max(w.x + w.y + w.z, 0.0001);

	vec2 uv_x = v_world_pos.zy * plank_scale;
	vec2 uv_y = v_world_pos.xz * plank_scale;
	vec2 uv_z = v_world_pos.xy * plank_scale;

	float pat = wood_pattern(uv_x) * w.x + wood_pattern(uv_y) * w.y + wood_pattern(uv_z) * w.z;

	// Warm honey-oak sunlit palette (matches cover_art.jpg warm cedar planks)
	vec3 warm_wood = mix(wood_tint.rgb, wood_tint.rgb * vec3(1.12, 1.04, 0.92), 0.35);
	vec3 col = mix(warm_wood * 0.62, warm_wood * (1.02 + grain_strength), pat);

	vec3 orm = texture(texture_orm, uv_x).rgb * w.x
		+ texture(texture_orm, uv_y).rgb * w.y
		+ texture(texture_orm, uv_z).rgb * w.z;

	vec3 nx = texture(texture_normal, uv_x).rgb * 2.0 - 1.0;
	vec3 ny = texture(texture_normal, uv_y).rgb * 2.0 - 1.0;
	vec3 nz = texture(texture_normal, uv_z).rgb * 2.0 - 1.0;
	vec3 n_blend = normalize(nx * w.x + ny * w.y + nz * w.z);

	NORMAL_MAP = n_blend * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_scale;

	AO = mix(orm.r, pat, 0.45);
	AO_LIGHT_AFFECT = 0.62;
	ALBEDO = col;
	ROUGHNESS = clamp(mix(roughness, orm.g, 0.42) + (1.0 - pat) * 0.14, 0.25, 0.92);
	METALLIC = 0.0;
	SPECULAR = 0.38;

	RIM = rim_strength * 0.7;
	RIM_TINT = 0.45;
}
