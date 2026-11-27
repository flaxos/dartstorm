// Holographic hexagonal forcefield bubble for the Foam Shield (1.0 Overhaul).
// Triplanar model-space hex grid eliminates SphereMesh polar pinching; depth_draw_never fixes sorting.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 albedo_color : source_color = vec4(0.2, 0.85, 1.0, 0.38);
uniform float hex_scale = 5.5;
uniform float hex_line_thickness = 0.08;
uniform float fresnel_power = 2.2;
uniform float pulse_speed = 2.6;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_local_pos;
varying vec3 v_local_normal;

vec2 hex_grid(vec2 p) {
	const vec2 r = vec2(1.0, 1.7320508);
	const vec2 h = r * 0.5;
	vec2 a = mod(p, r) - h;
	vec2 b = mod(p - h, r) - h;
	vec2 g = dot(a, a) < dot(b, b) ? a : b;
	float edge = 0.5 - max(dot(abs(g), vec2(0.5, 0.8660254)), abs(g.x));
	return vec2(edge, length(g));
}

void vertex() {
	v_local_pos = VERTEX;
	v_local_normal = normalize(NORMAL);
}

void fragment() {
	// Triplanar hex grid in object space so poles have crisp hexagons with zero pinching
	vec3 w = pow(abs(v_local_normal), vec3(6.0));
	w /= max(w.x + w.y + w.z, 0.0001);

	float hx = 1.0 - smoothstep(0.0, hex_line_thickness, hex_grid(v_local_pos.zy * hex_scale).x);
	float hy = 1.0 - smoothstep(0.0, hex_line_thickness, hex_grid(v_local_pos.xz * hex_scale).x);
	float hz = 1.0 - smoothstep(0.0, hex_line_thickness, hex_grid(v_local_pos.xy * hex_scale).x);
	float hex_line = clamp(hx * w.x + hy * w.y + hz * w.z, 0.0, 1.0);

	// Rising holographic scanline wave
	float scan = smoothstep(0.75, 1.0, sin(v_local_pos.y * 5.0 - TIME * 4.5) * 0.5 + 0.5) * 0.25;

	float fresnel = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), fresnel_power);
	float pulse = 0.88 + 0.12 * sin(TIME * pulse_speed);

	vec3 col = mix(albedo_color.rgb, vec3(1.0, 1.0, 1.0), hit_flash);
	col += vec3(0.35, 0.72, 1.0) * (hex_line * 1.1 + scan);

	float alpha = (fresnel * 0.68 + hex_line * 0.42 + scan + hit_flash * 0.65) * pulse * albedo_color.a;
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 0.92);
}
