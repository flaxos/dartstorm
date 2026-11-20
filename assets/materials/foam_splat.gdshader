// Cartoon foam splatter shader: juicy blob with satellite droplets, wet highlight, and bubble dissolve.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec4 splat_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float fizz_progress : hint_range(0.0, 1.0) = 0.0;
uniform float seed_val : hint_range(0.0, 100.0) = 1.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float r = length(uv);
	float angle = atan(uv.y, uv.x);

	// Organic wobbling perimeter for central blob
	float wobble = sin(angle * 5.0 + seed_val) * 0.04 + cos(angle * 3.0 - seed_val * 2.0) * 0.03;
	float center_mask = smoothstep(0.28 + wobble, 0.25 + wobble, r);

	// 5 satellite splash droplets around the perimeter
	float drops = 0.0;
	for (int i = 0; i < 5; i++) {
		float a = float(i) * 1.2566 + seed_val;
		float dist = 0.36 + sin(float(i) * 3.14 + seed_val) * 0.06;
		vec2 drop_center = vec2(cos(a), sin(a)) * dist;
		float drop_r = length(uv - drop_center);
		float drop_size = 0.045 + sin(float(i) * 2.7) * 0.015;
		drops += smoothstep(drop_size, drop_size * 0.7, drop_r);
	}

	float shape = clamp(center_mask + drops, 0.0, 1.0);
	if (shape <= 0.01) {
		discard;
	}

	// Cartoon wet highlight near upper-left
	vec2 spec_offset = uv - vec2(-0.08, 0.08);
	float spec_r = length(spec_offset);
	float spec = smoothstep(0.09, 0.04, spec_r) * 0.35;

	// Fizz-out dissolve with tiny foam bubbles
	if (fizz_progress > 0.0) {
		float bubble_noise = sin(uv.x * 45.0) * cos(uv.y * 45.0) * 0.5 + 0.5;
		float dissolve_edge = fizz_progress * 1.2;
		if (shape - (1.0 - bubble_noise) * fizz_progress < dissolve_edge) {
			discard;
		}
		shape *= (1.0 - fizz_progress);
	}

	vec3 col = splat_color.rgb + vec3(spec);
	ALBEDO = col;
	ALPHA = splat_color.a * shape;
}
