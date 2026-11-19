extends Node3D

const BASE_HEIGHT := 0.018432617

func _ready() -> void:
	await get_tree().physics_frame
	_seat_wooden_visuals(get_parent())

func _seat_wooden_visuals(node: Node) -> void:
	if node is AnimalCharacter or node is RigidBody3D or node.is_in_group("floor_seated_prop"):
		return
	if node is Node3D and node.scene_file_path.ends_with(".glb"):
		var visual := node as Node3D
		if visual.global_position.y < 0.25:
			var position := visual.global_position
			var ray := PhysicsRayQueryParameters3D.create(Vector3(position.x, 1.0, position.z), Vector3(position.x, -0.1, position.z), 1 << 20)
			var hit := get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty():
				visual.global_position.y += maxf(0.0, hit.position.y - BASE_HEIGHT)
		return
	for child in node.get_children():
		_seat_wooden_visuals(child)
