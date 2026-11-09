extends AnimalCharacter

@export var break_speed_threshold: float = 6.0
@export var dash_impulse: float = 5.5 

func _ready() -> void:
	max_speed = 3.0
	weight = 3.0
	push_force = 8.0

func perform_special_action() -> void:
	var dir := _get_input_direction()
	if dir == Vector3.ZERO:
		dir = Vector3(-1.0 if sprite.flip_h else 1.0, 0.0, 0.0)
	velocity.x = dir.x * dash_impulse
	velocity.z = dir.z * dash_impulse
	print("Boar rams")

func _on_slide_collision(collision: KinematicCollision3D, velocity_before_move: Vector3) -> void:
	var collider := collision.get_collider()
	var horizontal_speed := Vector2(velocity_before_move.x, velocity_before_move.z).length()
	
	if collider.is_in_group("breakable") and horizontal_speed >= break_speed_threshold:
		if collider.has_method("destroy"):
			collider.destroy()
		else:
			collider.queue_free()
		velocity.x = velocity_before_move.x * 0.7
		velocity.z = velocity_before_move.z * 0.7
