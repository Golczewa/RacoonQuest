shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

group_uniforms Color_Cycle;
uniform vec4 color_a : source_color = vec4(0.55, 0.78, 0.95, 0.45);
uniform vec4 color_b : source_color = vec4(0.72, 0.48, 0.92, 0.45);
uniform vec4 color_c : source_color = vec4(0.35, 0.88, 0.82, 0.45);
uniform float color_shift_speed : hint_range(0.0, 3.0, 0.01) = 0.25;
uniform bool use_three_colors = true;

group_uniforms Mist_Noise;
uniform float mist_scale : hint_range(0.1, 10.0, 0.05) = 1.6;
uniform float mist_density : hint_range(0.0, 2.5, 0.02) = 0.75;
uniform float softness : hint_range(0.05, 1.0, 0.01) = 0.45;
uniform vec3 drift_speed = vec3(0.08, 0.04, 0.06);

group_uniforms Edge_Fade;
uniform float edge_softness : hint_range(0.2, 6.0, 0.05) = 1.4;
uniform float edge_fade_strength : hint_range(0.0, 1.0, 0.05) = 0.65;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// Lekki szum proceduralny 3D oparty na hashu wartościowym
float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3d(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);

	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));

	float nx00 = mix(n000, n100, u.x);
	float nx10 = mix(n010, n110, u.x);
	float nx01 = mix(n001, n101, u.x);
	float nx11 = mix(n011, n111, u.x);

	float nxy0 = mix(nx00, nx10, u.y);
	float nxy1 = mix(nx01, nx11, u.y);

	return mix(nxy0, nxy1, u.z);
}

// Wielowarstwowy szum (FBM) dający efekt kłębiących się pasm mgły
float fbm(vec3 p) {
	float value = 0.0;
	float amp = 0.5;
	float freq = 1.0;

	for (int i = 0; i < 4; i++) {
		value += amp * noise3d(p * freq);
		freq *= 2.03;
		amp *= 0.5;
	}
	return value;
}

vec3 get_shifted_color(float t) {
	if (!use_three_colors) {
		float mix_ab = 0.5 + 0.5 * sin(t);
		return mix(color_a.rgb, color_b.rgb, mix_ab);
	}

	// Płynne przejście cykliczne przez 3 kolory (A -> B -> C -> A)
	float phase = mod(t * 0.15915494, 3.0); // t / (2*PI) * 3 -> zakres [0.0, 3.0)
	if (phase < 1.0) {
		return mix(color_a.rgb, color_b.rgb, smoothstep(0.0, 1.0, phase));
	} else if (phase < 2.0) {
		return mix(color_b.rgb, color_c.rgb, smoothstep(1.0, 2.0, phase));
	} else {
		return mix(color_c.rgb, color_a.rgb, smoothstep(2.0, 3.0, phase));
	}
}

void fragment() {
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
	vec3 n = FRONT_FACING ? normalize(world_normal) : -normalize(world_normal);

	// Miękki zanik na skrajnych krawędziach obiektu, aby uniknąć twardego obrysu
	float ndotv = clamp(abs(dot(n, view_dir)), 0.0, 1.0);
	float edge_mask = mix(1.0, pow(ndotv, edge_softness), edge_fade_strength);

	// Dwie warstwy szumu poruszające się z różną prędkością dla głębi mgły
	vec3 pos_layer_1 = world_pos * mist_scale + drift_speed * TIME;
	vec3 pos_layer_2 = world_pos * (mist_scale * 1.45) - drift_speed * (TIME * 0.65);

	float mist_1 = fbm(pos_layer_1);
	float mist_2 = fbm(pos_layer_2);
	float combined_mist = mix(mist_1, mist_2, 0.45);

	// Rozmiękczenie progów szumu
	float low_cut = clamp(0.45 - softness * 0.35, 0.05, 0.45);
	float high_cut = clamp(0.68 + softness * 0.25, 0.55, 0.95);
	float mist_shape = smoothstep(low_cut, high_cut, combined_mist);

	// Zmiana kolorów w czasie oraz delikatna wariacja barwy w samych kłębach mgły
	float time_phase = TIME * color_shift_speed;
	vec3 base_shift = get_shifted_color(time_phase);
	vec3 swirl_shift = get_shifted_color(time_phase + combined_mist * 1.6);
	vec3 final_color = mix(base_shift, swirl_shift, 0.35);

	// Bazowa alfa brana z uśrednionej przezroczystości kolorów
	float avg_alpha = use_three_colors
		? (color_a.a + color_b.a + color_c.a) / 3.0
		: (color_a.a + color_b.a) * 0.5;

	float final_alpha = clamp(mist_shape * mist_density * edge_mask * avg_alpha * 1.8, 0.0, 0.95);

	ALBEDO = final_color;
	ALPHA = final_alpha;
}