// AAA Stylized Cartoon Water Shader
// Features:
// - Animated dual-frequency wave normals
// - Depth absorption gradient (shallow turquoise to deep sapphire)
// - Shoreline / rim foam edge
// - Glinting specular reflections & Fresnel rim
// - Electrified energy pulse modulation

shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.35, 0.78, 0.95, 0.70);
uniform vec4 deep_color : source_color = vec4(0.10, 0.40, 0.82, 0.88);
uniform vec4 foam_color : source_color = vec4(0.92, 0.98, 1.0, 0.95);
uniform float wave_speed : hint_range(0.1, 5.0) = 1.2;
uniform float wave_frequency : hint_range(0.5, 20.0) = 4.5;
uniform float wave_height : hint_range(0.0, 0.2) = 0.025;
uniform float foam_edge_width : hint_range(0.01, 0.3) = 0.08;
uniform float electrified : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_world_pos;
varying vec2 v_uv;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_uv = UV;
	
	// Gentle surface wave displacement
	float w1 = sin(v_world_pos.x * wave_frequency + TIME * wave_speed) * cos(v_world_pos.z * wave_frequency * 0.8 + TIME * wave_speed * 1.2);
	float w2 = sin((v_world_pos.x + v_world_pos.z) * wave_frequency * 0.5 - TIME * wave_speed * 0.8);
	VERTEX.y += (w1 + w2) * wave_height;
}

void fragment() {
	// Circular disc distance from center for shoreline foam in puddles
	vec2 center_offset = v_uv - vec2(0.5);
	float dist = length(center_offset) * 2.0; // 0 at center, 1 at rim
	
	// Animated ripple normals
	float t = TIME * wave_speed;
	float n_wave1 = sin(v_world_pos.x * 6.0 + t * 2.0) * cos(v_world_pos.z * 6.0 - t * 1.5);
	float n_wave2 = cos(v_world_pos.x * 12.0 - t) * sin(v_world_pos.z * 12.0 + t * 1.7);
	vec3 wave_normal = normalize(vec3((n_wave1 + n_wave2) * 0.15, 1.0, (n_wave1 - n_wave2) * 0.15));
	NORMAL = normalize((VIEW_MATRIX * vec4(wave_normal, 0.0)).xyz);
	
	// Gradient from deep center to shallow edges
	vec4 water_col = mix(deep_color, shallow_color, smoothstep(0.0, 0.85, dist));
	
	// Shoreline foam ring along perimeter
	float foam = smoothstep(1.0 - foam_edge_width, 1.0, dist + sin(t * 3.0 + atan(center_offset.y, center_offset.x) * 8.0) * 0.02);
	vec4 final_col = mix(water_col, foam_color, foam * 0.75);
	
	// Electrified electric zap crackle
	if (electrified > 0.01) {
		float crackle = sin(t * 22.0 + v_world_pos.x * 24.0) * cos(t * 18.0 + v_world_pos.z * 24.0);
		crackle = step(0.65, crackle);
		vec3 electric_blue = vec3(0.4, 0.9, 1.0) * 2.5;
		final_col.rgb = mix(final_col.rgb, electric_blue, crackle * electrified);
		EMISSION = electric_blue * crackle * electrified;
	}
	
	ALBEDO = final_col.rgb;
	ALPHA = final_col.a;
	ROUGHNESS = 0.05 + foam * 0.35;
	METALLIC = 0.1;
	SPECULAR = 0.95;
	
	// Glancing Fresnel reflection
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	RIM = fresnel * 0.65;
	RIM_TINT = 0.2;
}
