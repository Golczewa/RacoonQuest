extends StaticBody3D

@export_range(0.0, 0.15, 0.005) var flicker_amount := 0.035
@onready var flame_light: OmniLight3D = $FlameLight
var base_energy := 0.0
var elapsed := 0.0

func _ready() -> void:
	base_energy = flame_light.light_energy
	elapsed = global_position.x * 0.71 + global_position.z * 1.17
	for mesh_node: MeshInstance3D in $Model.find_children("*", "MeshInstance3D", true, false):
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := mesh_node.get_active_material(0) as StandardMaterial3D
		if material != null:
			var local_material := ShaderMaterial.new()
			local_material.shader = preload("res://shaders/painted_torch.gdshader")
			local_material.set_shader_parameter("paint_map", material.albedo_texture)
			local_material.set_shader_parameter("flame_map", material.emission_texture)
			local_material.set_shader_parameter("normal_map", material.normal_texture)
			local_material.set_shader_parameter("roughness_map", material.roughness_texture)
			mesh_node.material_override = local_material
	await get_tree().physics_frame
	var position := global_position
	var ray := PhysicsRayQueryParameters3D.create(Vector3(position.x, 1.0, position.z), Vector3(position.x, -0.1, position.z), 1 << 20)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		global_position.y = hit.position.y + 0.002

func _process(delta: float) -> void:
	elapsed += delta
	var flicker := sin(elapsed * 5.3) * 0.55 + sin(elapsed * 8.7 + 1.3) * 0.30 + sin(elapsed * 13.1) * 0.15
	flame_light.light_energy = base_energy * (1.0 + flicker * flicker_amount)
