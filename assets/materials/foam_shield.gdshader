// Holographic hexagonal forcefield bubble for the Foam Shield power-up.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, unshaded;

uniform vec4 albedo_color : source_color = vec4(0.2, 0.85, 1.0, 0.35);
uniform float hex_scale = 14.0;
uniform float hex_line_thickness = 0.07;
uniform float fresnel_power = 2.2;
uniform float pulse_speed = 2.5;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;

vec2 hex_grid(vec2 p) {
	const vec2 r = vec2(1.0, 1.7320508);
	const vec2 h = r * 0.5;
	vec2 a = mod(p, r) - h;
	vec2 b = mod(p - h, r) - h;
	vec2 g = dot(a, a) < dot(b, b) ? a : b;
	float edge = 0.5 - max(dot(abs(g), vec2(0.5, 0.8660254)), abs(g.x));
	return vec2(edge, length(g));
}

void fragment() {
	vec2 p = UV * hex_scale;
	vec2 h = hex_grid(p);
	float edge = h.x;

	// Hexagonal wireframe grid lines
	float hex_line = 1.0 - smoothstep(0.0, hex_line_thickness, edge);

	// Edge-enhancing Fresnel glow
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

	// Pulsing shimmer
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);

	vec3 col = mix(albedo_color.rgb, vec3(1.0, 1.0, 1.0), hit_flash);
	col += vec3(0.3, 0.6, 1.0) * hex_line;

	float alpha = (fresnel * 0.65 + hex_line * 0.45 + hit_flash * 0.6) * pulse * albedo_color.a;
	ALBEDO = col;
	ALPHA = clamp(alpha, 0.0, 0.95);
}
