extends AnimalCharacter

@export var projectile_scene: PackedScene = preload("res://scenes/player/racoon/projectile.tscn")
@export var spawn_height_offset: float = 0.6

func _ready() -> void:
	super._ready()
	weight = 1.0
	push_force = 2.0

func perform_special_action() -> void:
	if projectile_scene == null:
		return
		
	var aim_dir := _get_mouse_aim_direction()
	if aim_dir == Vector3.ZERO:
		aim_dir = Vector3(-1.0 if sprite.flip_h else 1.0, 0.0, 0.0)
		
	if aim_dir.x < -0.05:
		sprite.flip_h = true
	elif aim_dir.x > 0.05:
		sprite.flip_h = false
		
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector3(0.0, spawn_height_offset, 0.0) + aim_dir * 0.6
	proj.direction = aim_dir
	proj.shooter = self

func _get_mouse_aim_direction() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.ZERO
		
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_normal := camera.project_ray_normal(mouse_pos)
	
	var aim_plane := Plane(Vector3.UP, global_position.y + spawn_height_offset)
	var intersection = aim_plane.intersects_ray(ray_origin, ray_normal)
	
	if intersection != null:
		var dir: Vector3 = intersection - (global_position + Vector3(0.0, spawn_height_offset, 0.0))
		dir.y = 0.0
		return dir.normalized()
		
	return Vector3.ZERO
