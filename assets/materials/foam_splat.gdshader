// Cartoon foam splatter shader (1.0 Overhaul):
// Juicy blob with satellite droplets, glossy highlight, bubble fizz dissolve, and clean alpha sorting.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, unshaded;

uniform vec4 splat_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float fizz_progress : hint_range(0.0, 1.0) = 0.0;
uniform float seed_val : hint_range(0.0, 100.0) = 1.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float r = length(uv);
	float angle = atan(uv.y, uv.x);

	float wobble = sin(angle * 5.0 + seed_val) * 0.04 + cos(angle * 3.0 - seed_val * 2.0) * 0.03;
	float center_mask = smoothstep(0.28 + wobble, 0.24 + wobble, r);

	float drops = 0.0;
	for (int i = 0; i < 5; i++) {
		float a = float(i) * 1.2566 + seed_val;
		float dist = 0.36 + sin(float(i) * 3.14 + seed_val) * 0.06;
		vec2 drop_center = vec2(cos(a), sin(a)) * dist;
		float drop_r = length(uv - drop_center);
		float drop_size = 0.048 + sin(float(i) * 2.7) * 0.014;
		drops += smoothstep(drop_size, drop_size * 0.65, drop_r);
	}

	float shape = clamp(center_mask + drops, 0.0, 1.0);
	if (shape <= 0.02) {
		discard;
	}

	// Darkened outer cartoon ink rim + juicy wet highlight
	float rim_dark = smoothstep(0.22 + wobble, 0.27 + wobble, r) * 0.18;
	vec2 spec_offset = uv - vec2(-0.08, 0.08);
	float spec = smoothstep(0.09, 0.035, length(spec_offset)) * 0.38;

	// Smooth bubbly fizz-out dissolve
	float alpha_mult = 1.0;
	if (fizz_progress > 0.0) {
		float bubble_noise = sin(uv.x * 46.0 + seed_val) * cos(uv.y * 46.0 - seed_val) * 0.5 + 0.5;
		float edge = shape - (1.0 - bubble_noise) * fizz_progress - fizz_progress * 1.15;
		if (edge < 0.0) {
			discard;
		}
		alpha_mult = smoothstep(0.0, 0.18, edge) * (1.0 - fizz_progress * 0.85);
	}

	vec3 col = splat_color.rgb * (1.0 - rim_dark) + vec3(spec);
	ALBEDO = col;
	ALPHA = splat_color.a * shape * alpha_mult;
}
