extends CharacterBody2D


const SPEED = 300.0


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left","move_right","move_down","move_up")
	if direction:
		velocity.x = direction * SPEED
	move_and_slide()
