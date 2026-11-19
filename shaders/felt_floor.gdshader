shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D felt_fibers : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 felt_color : source_color = vec4(0.18, 0.255, 0.19, 1.0);
uniform float tile_meters : hint_range(0.5, 20.0) = 10.0;
uniform float fiber_relief : hint_range(0.0, 2.0) = 0.35;
varying vec2 floor_position;

void vertex() {
	floor_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 uv = floor_position / tile_meters;
	vec2 texel = 1.0 / vec2(textureSize(felt_fibers, 0));
	float fiber = texture(felt_fibers, uv).r;
	float dx = texture(felt_fibers, uv + vec2(texel.x, 0.0)).r - fiber;
	float dy = texture(felt_fibers, uv + vec2(0.0, texel.y)).r - fiber;
	ALBEDO = felt_color.rgb * COLOR.rgb * (1.0 + (fiber - 0.60) * 1.2);
	ROUGHNESS = 0.98;
	METALLIC = 0.0;
	NORMAL_MAP = normalize(vec3(-dx * fiber_relief, -dy * fiber_relief, 1.0)) * 0.5 + 0.5;
}
