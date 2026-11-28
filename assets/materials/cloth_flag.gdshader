// DARTSTORM v2.0.0 Waving Cloth Banner & Team Flag Shader
// Smooth vertex wind-ripple anchored along UV.x == 0 (flagpole side) with
// 3-band chromatic cel shading (compatible with Forward+ and Compatibility).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 flag_color : source_color = vec4(0.15, 0.48, 1.0, 1.0);
uniform vec4 stripe_color : source_color = vec4(1.0, 0.96, 0.88, 1.0);
uniform float wave_speed : hint_range(0.5, 12.0) = 4.6;
uniform float wave_amp : hint_range(0.0, 0.6) = 0.24;
uniform float wave_freq : hint_range(1.0, 14.0) = 5.5;
uniform vec4 shadow_tint : source_color = vec4(0.22, 0.26, 0.56, 1.0);

varying float v_pin;
varying vec2 v_uv;

void vertex() {
	v_uv = UV;
	// Pin along the flagpole edge (UV.x == 0) so the flag stays attached cleanly.
	float pin = clamp(UV.x, 0.0, 1.0);
	v_pin = pin;
	float w1 = sin(TIME * wave_speed - UV.x * wave_freq + UV.y * 1.4);
	float w2 = cos(TIME * wave_speed * 1.65 - UV.x * wave_freq * 1.9 - UV.y * 2.1) * 0.32;
	float flutter = (w1 + w2) * wave_amp * (pin * pin);
	VERTEX.x += flutter;
	VERTEX.y += sin(TIME * wave_speed * 0.8 - UV.x * 3.2) * wave_amp * 0.25 * pin;
}

void fragment() {
	// Crisp horizontal racing stripe across middle of flag for unmistakable team read
	float stripe = step(0.41, v_uv.y) * step(v_uv.y, 0.59);
	vec3 col = mix(flag_color.rgb, stripe_color.rgb, stripe * 0.85);
	ALBEDO = col;
	ROUGHNESS = 0.62;
	METALLIC = 0.0;
	EMISSION = col * 0.08;
}

void light() {
	float ndl = abs(dot(NORMAL, LIGHT));
	float lit_val = ndl * 0.65 + 0.35;
	float att = smoothstep(0.15, 0.65, ATTENUATION);
	float band_mid = smoothstep(0.40, 0.52, lit_val);
	float band_hi = smoothstep(0.68, 0.80, lit_val);
	float cel = mix(0.44, mix(0.78, 1.04, band_hi), band_mid);
	cel = mix(0.48, cel, att);
	vec3 shadow_col = ALBEDO * mix(vec3(1.0), shadow_tint.rgb * 1.75, 0.40);
	vec3 tinted = mix(shadow_col, ALBEDO, smoothstep(0.44, 0.84, cel));
	DIFFUSE_LIGHT += tinted * LIGHT_COLOR * (cel / PI);
}
