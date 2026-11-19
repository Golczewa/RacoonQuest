extends Node3D

@export var rand_seed:=5
@export var stuff_count:=10
@export var stuff:Array[PackedScene]=[]
@export var yaw_variation_degrees := 25.0
@export var minimum_spacing := 1.3
@export var path_half_width := 1.1
@export var clear_path: Curve3D

var generator:=RandomNumberGenerator.new()
var placed_points: Array[Vector2] = []
var torch_points: Array[Vector2] = []

func _ready() -> void:
	$MeshInstance3D.hide()
	generator.seed=rand_seed
	call_deferred("gerate")
	

func gerate()->void:
	if stuff.is_empty():
		return
	for child in get_parent().get_children():
		if child is Node3D and child.scene_file_path.ends_with("/wooden_bush.tscn"):
			placed_points.append(Vector2(child.global_position.x, child.global_position.z))
	for torch: Node3D in get_parent().find_children("*", "Node3D", true, false):
		if torch.is_in_group("wooden_torches"):
			placed_points.append(Vector2(torch.global_position.x, torch.global_position.z))
			torch_points.append(Vector2(torch.global_position.x, torch.global_position.z))
	for i in range(stuff_count):
		var point := Vector3.ZERO
		var found := false
		for attempt in range(100):
			point = get_random_point()
			if is_free_point(point):
				found = true
				break
		if not found:
			continue
		var prop:Node3D=stuff[generator.randi_range(0,stuff.size()-1)].instantiate()
		get_parent().add_child(prop)
		prop.global_position=point
		prop.rotation.y = deg_to_rad(generator.randf_range(-yaw_variation_degrees, yaw_variation_degrees))
		prop.set_meta("scatter_generated", true)
		placed_points.append(Vector2(point.x, point.z))


func is_free_point(point: Vector3) -> bool:
	if clear_path != null:
		var room_point: Vector3 = (get_parent() as Node3D).to_local(point)
		var nearest := clear_path.get_closest_point(room_point)
		if Vector2(room_point.x - nearest.x, room_point.z - nearest.z).length() < path_half_width:
			return false
	else:
		var region_depth := global_transform.basis.get_scale().z
		if absf(to_local(point).z) * region_depth < path_half_width:
			return false
	var point_2d := Vector2(point.x, point.z)
	for torch_point in torch_points:
		if point_2d.distance_to(torch_point) < 2.2:
			return false
	for placed in placed_points:
		if point_2d.distance_to(placed) < minimum_spacing:
			return false
	for marker in get_parent().find_children("*", "Marker3D", false, false):
		var spawn := marker as Marker3D
		if point_2d.distance_to(Vector2(spawn.global_position.x, spawn.global_position.z)) < 2.0:
			return false
	return true


func get_random_point() -> Vector3:
	var local_point := Vector3(generator.randf_range(-0.5, 0.5), 0.0, generator.randf_range(-0.5, 0.5))
	return to_global(local_point)
