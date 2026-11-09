extends Node3D

@export_range(0.0, 35.0, 0.5) var movement_turn_degrees: float = 18.0
@export_range(1.0, 20.0, 0.5) var turn_smoothing: float = 9.0

@onready var sprite: AnimatedSprite3D = get_node("../AnimatedSprite3D")
@onready var character: AnimalCharacter = get_parent().get_parent() as AnimalCharacter
@onready var facing: Node3D = $Facing
var poses: Array[Node3D] = []

var local_materials: Array[StandardMaterial3D] = []
var previous_tint := Color(-1, -1, -1, -1)
var mesh_nodes: Array[MeshInstance3D] = []
var original_meshes: Array[Mesh] = []
var mirrored_meshes: Array[Mesh] = []
var flipped := false
var resting_yaw := 0.0

func _ready() -> void:
	resting_yaw = facing.rotation.y
	for pose: Node3D in facing.get_children():
		poses.append(pose)
	sprite.hide()
	for mesh_node: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh_nodes.append(mesh_node)
		original_meshes.append(mesh_node.mesh)
		mirrored_meshes.append(_mirror_mesh(mesh_node.mesh))
		var material := mesh_node.get_active_material(0) as StandardMaterial3D
		if material != null:
			var local_material := material.duplicate() as StandardMaterial3D
			mesh_node.material_override = local_material
			local_materials.append(local_material)
	_sync_visuals()

func _mirror_mesh(source: Mesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	for surface in range(source.get_surface_count()):
		var arrays := source.surface_get_arrays(surface).duplicate(true)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for index in range(vertices.size()):
			vertices[index].x *= -1.0
			normals[index].x *= -1.0
		for index in range(0, tangents.size(), 4):
			tangents[index] *= -1.0
			tangents[index + 3] *= -1.0
		for index in range(0, indices.size(), 3):
			var second := indices[index + 1]
			indices[index + 1] = indices[index + 2]
			indices[index + 2] = second
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TANGENT] = tangents
		arrays[Mesh.ARRAY_INDEX] = indices
		for channel in range(Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM3 + 1):
			arrays[channel] = null
		result.add_surface_from_arrays(source.surface_get_primitive_type(surface), arrays)
		result.surface_set_material(surface, source.surface_get_material(surface))
	return result

func _process(delta: float) -> void:
	if sprite.sprite_frames.has_animation("walk"):
		if Vector2(character.velocity.x, character.velocity.z).length() > 0.15:
			if not sprite.is_playing():
				sprite.play("walk")
		else:
			sprite.stop()
			sprite.frame = 0
	_sync_visuals()
	_update_movement_turn(delta)

func _update_movement_turn(delta: float) -> void:
	var local_velocity := global_basis.orthonormalized().inverse() * character.velocity
	var movement := Vector2(local_velocity.x, local_velocity.z)
	var turn := 0.0
	if movement.length() > 0.15:
		var direction := movement.normalized()
		var facing_sign := -1.0 if sprite.flip_h else 1.0
		turn = clampf(direction.x * 0.3 - direction.y * facing_sign, -1.0, 1.0)
	var target_yaw := resting_yaw + turn * deg_to_rad(movement_turn_degrees)
	facing.rotation.y = lerp_angle(facing.rotation.y, target_yaw, 1.0 - exp(-turn_smoothing * delta))

func _sync_visuals() -> void:
	if flipped != sprite.flip_h:
		flipped = sprite.flip_h
		for index in range(mesh_nodes.size()):
			mesh_nodes[index].mesh = mirrored_meshes[index] if flipped else original_meshes[index]
	var frame_index := mini(sprite.frame, poses.size() - 1)
	for index in range(poses.size()):
		poses[index].visible = index == frame_index
	if sprite.modulate != previous_tint:
		previous_tint = sprite.modulate
		for material in local_materials:
			material.albedo_color = previous_tint

