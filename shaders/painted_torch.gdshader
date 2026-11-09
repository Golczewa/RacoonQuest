shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D paint_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D flame_map : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D roughness_map : filter_linear_mipmap_anisotropic;

void fragment() {
	vec3 paint = texture(paint_map, UV).rgb;
	vec3 flame = texture(flame_map, UV).rgb;
	float painted_flame = smoothstep(0.005, 0.02, max(flame.r, max(flame.g, flame.b)));
	ALBEDO = paint * (1.0 - painted_flame);
	float hot_core = smoothstep(0.22, 0.72, flame.g);
	EMISSION = flame * mix(0.9, 1.9, hot_core);
	NORMAL_MAP = texture(normal_map, UV).rgb;
	ROUGHNESS = texture(roughness_map, UV).r;
}
