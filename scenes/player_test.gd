extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 4.5

@onready var sprite: AnimatedSprite3D = $Sprite3D


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Input relative to the camera's yaw, so "up" always means "away from the screen"
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var cam := get_viewport().get_camera_3d()
	var cam_basis := Basis(Vector3.UP, cam.global_rotation.y)
	var direction := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		sprite.play("walk")

		# Flip the sprite to face left/right on screen
		if input_dir.x == 0:
			sprite.flip_h = input_dir.x < 0
	else:
		sprite.stop()
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
