// DARTSTORM v2.0.0 Pixar / Fortnite Sunlit Backyard Lawn Shader:
// Layered painterly grass-blade micro-texture + soft normal relief + alternating mower
// stripes + drifting sunlight wind crests + velvet Fresnel sheen.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 color_a : source_color = vec3(0.36, 0.72, 0.25);
uniform vec3 color_b : source_color = vec3(0.25, 0.58, 0.20);
uniform sampler2D grass_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool use_grass_textures = false;
uniform float stripe_width = 4.2;
uniform float tuft_scale = 6.5;
uniform float wind_speed = 1.4;
uniform float wind_strength = 0.035;

varying vec3 world_position;
varying vec3 v_world_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float stripe_x = smoothstep(0.30, 0.70, sin(world_position.x * 3.14159 / max(stripe_width, 0.5)) * 0.5 + 0.5);
	float stripe_z = smoothstep(0.30, 0.70, sin(world_position.z * 3.14159 / max(stripe_width, 0.5)) * 0.5 + 0.5);
	float stripe = mix(stripe_x, stripe_z, 0.30);

	float cam_dist = length(VERTEX);
	float detail_fade = 1.0 - smoothstep(16.0, 48.0, cam_dist);
	float macro_patch = value_noise(world_position.xz * 0.14);
	float clover_patch = value_noise(world_position.xz * 0.45 + vec2(7.3, 2.1));
	float wind_wave = value_noise(world_position.xz * 0.11 + vec2(TIME * wind_speed * 0.18, TIME * wind_speed * 0.11));

	float blend_t = clamp(stripe * 0.46 + macro_patch * 0.28 + (clover_patch - 0.5) * 0.22 + (wind_wave - 0.5) * 0.16, 0.0, 1.0);
	vec3 col = mix(color_a, color_b, blend_t);

	if (use_grass_textures) {
		vec2 g_uv = world_position.xz * 0.28;
		vec2 g_uv2 = world_position.xz * 0.11 + vec2(0.37, 0.61);
		vec3 tex_fine = texture(grass_albedo, g_uv).rgb;
		vec3 tex_macro = texture(grass_albedo, g_uv2).rgb;
		vec3 tex_mix = mix(tex_macro, tex_fine, 0.62 * detail_fade + 0.18);
		col = mix(col, col * (tex_mix * 2.05), 0.55);
		NORMAL_MAP = texture(grass_normal, g_uv).rgb;
		NORMAL_MAP_DEPTH = 0.62 * detail_fade + 0.18;
	} else if (abs(v_world_normal.y) > 0.5 && detail_fade > 0.01) {
		float tuft_fine = value_noise(world_position.xz * tuft_scale);
		float n_a = value_noise(world_position.xz * tuft_scale + vec2(0.15, 0.0));
		float n_b = value_noise(world_position.xz * tuft_scale + vec2(0.0, 0.15));
		vec3 grass_n = normalize(vec3((n_a - tuft_fine) * 0.5 * detail_fade, 1.0, (n_b - tuft_fine) * 0.5 * detail_fade));
		NORMAL = normalize((VIEW_MATRIX * vec4(grass_n, 0.0)).xyz);
	}

	// Golden-hour sunlit grass tips in wind crests
	col += vec3(0.06, 0.07, 0.015) * smoothstep(0.56, 0.90, wind_wave) * (0.45 + detail_fade * 0.55);

	ALBEDO = col;
	ROUGHNESS = mix(0.88, 0.74, stripe * 0.5 + clover_patch * 0.5);
	SPECULAR = 0.24;
	RIM = 0.34;
	RIM_TINT = 0.55;
}
