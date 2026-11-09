class_name AnimalCharacter
extends CharacterBody3D

@export_group("Movement Stats")
@export var max_speed: float = 5.0
@export var acceleration: float = 30.0
@export var friction: float = 50.0
@export var momentum_decay: float = 6.0
@export var jump_velocity: float = 6.3

@export_group("Physics & Puzzle Stats")
@export var weight: float = 1.0
@export var push_force: float = 2.0
@export_enum("low", "medium", "high") var weight_class: String = "medium"


@export_group("Animal Capabilities")
@export var is_active_player: bool = false

@onready var visuals: Node3D = $Visuals
@onready var sprite: AnimatedSprite3D = $Visuals/AnimatedSprite3D
@onready var swap_area: Area3D = $SwapArea

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	
	if is_active_player:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity
			
		var input_dir := _get_input_direction()
		_handle_movement(input_dir, delta)
		_update_visuals(input_dir)
		
		if Input.is_action_just_pressed("action_primary"):
			perform_special_action()
	else:
		_handle_movement(Vector3.ZERO, delta)
			
	var velocity_before_move := velocity
	move_and_slide()
	_handle_collisions(velocity_before_move)

func _handle_collisions(velocity_before_move: Vector3) -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()

		if collider is RigidBody3D:
			var normal := collision.get_normal()
			if abs(normal.y) < 0.3:
				var push_dir := Vector3(-normal.x, 0.0, -normal.z).normalized()
				collider.apply_central_impulse(push_dir * push_force * 0.15)

func _on_slide_collision(_collision: KinematicCollision3D, _velocity_before_move: Vector3) -> void:
	pass

func get_closest_swappable_animal() -> AnimalCharacter:
	var bodies := swap_area.get_overlapping_bodies()
	var closest_animal: AnimalCharacter = null
	var min_dist_sq: float = INF
	
	for body in bodies:
		if body is AnimalCharacter and body != self:
			var dist_sq := global_position.distance_squared_to(body.global_position)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				closest_animal = body
				
	return closest_animal

func _get_input_direction() -> Vector3:
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3(raw_input.x, 0.0, raw_input.y)
	var cam_basis := camera.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()
	return (right * raw_input.x + forward * -raw_input.y).limit_length(1.0)

func _handle_movement(direction: Vector3, delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var is_over_speed := horizontal_speed > max_speed + 0.5
	var current_accel := momentum_decay if is_over_speed else acceleration
	var current_friction := momentum_decay if is_over_speed else friction

	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * max_speed, current_accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * max_speed, current_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, current_friction * delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func _update_visuals(direction: Vector3) -> void:
	if direction.x < -0.05:
		sprite.flip_h = true
	elif direction.x > 0.05:
		sprite.flip_h = false
		
func perform_special_action() -> void:
	pass
