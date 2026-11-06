class_name AnimalCharacter
extends CharacterBody3D

@export_group("Movement Stats")
@export var max_speed: float = 5.0
@export var acceleration: float = 30.0
@export var friction: float = 50.0

@export_group("Animal Capabilities")
@export var is_active_player: bool = true

@onready var visuals: Node3D = $Visuals
@onready var sprite: AnimatedSprite3D = $Visuals/AnimatedSprite3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	
	if is_active_player:
		var input_dir := _get_input_direction()
		_handle_movement(input_dir, delta)
		_update_visuals(input_dir)
		
		if Input.is_action_just_pressed("action_primary"):
			perform_special_action()
	else:
		_handle_movement(Vector3.ZERO, delta)
		
	move_and_slide()

func _get_input_direction() -> Vector3:
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return Vector3(raw_input.x, 0.0, raw_input.y)

func _handle_movement(direction: Vector3, delta: float) -> void:
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * max_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

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
