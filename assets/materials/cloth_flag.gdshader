// DARTSTORM v2.0.0 Waving Cloth Banner & Team Flag Shader (Pixar Stylized PBR)
// Smooth vertex wind-ripple anchored along UV.x == 0 with soft backlit cloth shading.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 flag_color : source_color = vec4(0.15, 0.48, 1.0, 1.0);
uniform vec4 stripe_color : source_color = vec4(1.0, 0.96, 0.88, 1.0);
uniform float wave_speed : hint_range(0.5, 12.0) = 4.6;
uniform float wave_amp : hint_range(0.0, 0.6) = 0.24;
uniform float wave_freq : hint_range(1.0, 14.0) = 5.5;
uniform vec4 shadow_tint : source_color = vec4(0.22, 0.26, 0.56, 1.0);

varying vec2 v_uv;

void vertex() {
	v_uv = UV;
	float pin = clamp(UV.x, 0.0, 1.0);
	float w1 = sin(TIME * wave_speed - UV.x * wave_freq + UV.y * 1.4);
	float w2 = cos(TIME * wave_speed * 1.65 - UV.x * wave_freq * 1.9 - UV.y * 2.1) * 0.32;
	float flutter = (w1 + w2) * wave_amp * (pin * pin);
	VERTEX.x += flutter;
	VERTEX.y += sin(TIME * wave_speed * 0.8 - UV.x * 3.2) * wave_amp * 0.25 * pin;
}

void fragment() {
	float stripe = step(0.41, v_uv.y) * step(v_uv.y, 0.59);
	// Subtle woven fabric micro-stitch variation
	float weave = (sin(v_uv.x * 160.0) * sin(v_uv.y * 120.0)) * 0.025;
	vec3 col = mix(flag_color.rgb, stripe_color.rgb, stripe * 0.85) + weave;
	ALBEDO = col;
	ROUGHNESS = 0.78;
	METALLIC = 0.0;
	SPECULAR = 0.22;
	BACKLIGHT = col * 0.38;
	RIM = 0.32;
	RIM_TINT = 0.45;
}
