shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float radius = length(p);
	float core = exp(-radius * radius * 6.0);
	float spill = exp(-radius * radius * 2.7);
	float glow = mix(core, spill, 0.28) * (1.0 - smoothstep(0.70, 1.0, radius));
	ALBEDO = vec3(1.0, 0.40, 0.07) * glow * 0.52;
	ALPHA = glow * 0.46;
}
