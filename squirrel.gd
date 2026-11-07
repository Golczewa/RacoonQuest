extends AnimalCharacter

@export var climb_speed: float = 4.5
var is_climbing: bool = false

func _ready() -> void:
	super._ready()
	weight = 0.3 
	push_force = 0.5

func _physics_process(delta: float) -> void:
	var touching_climbable := _is_near_climbable_wall()
	var was_climbing := is_climbing
	
	if not touching_climbable:
		is_climbing = false
	elif is_active_player and Input.is_action_just_pressed("action_primary"):
		is_climbing = not is_climbing
	
	if was_climbing and not is_climbing and velocity.y > 0.0:
		velocity.y = 0.0
	
	if is_climbing and is_active_player:
		var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity.x = move_toward(velocity.x, raw_input.x * climb_speed, acceleration * delta)
		velocity.y = move_toward(velocity.y, -raw_input.y * climb_speed, acceleration * delta)
		velocity.z = -1.5
		_update_visuals(Vector3(raw_input.x, 0.0, 0.0))
		move_and_slide()
	else:
		super._physics_process(delta)

func _is_near_climbable_wall() -> bool:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_collider() and col.get_collider().is_in_group("climbable"):
			return true
	return false

func perform_special_action() -> void:
	if _is_near_climbable_wall():
		is_climbing = not is_climbing
		print("Squirrel climbing: ", is_climbing)
