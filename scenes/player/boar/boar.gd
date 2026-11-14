extends AnimalCharacter

@export var break_speed_threshold: float = 6.0
@export var dash_impulse: float = 5.5 

var running_from_bunny:=false
var bunny:VampBunny

func _ready() -> void:
	super._ready()
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
	elif running_from_bunny:
		if !bunny:
			running_from_bunny=false
			return
		if bunny.is_ring_active:
			return
		var direction = -(bunny.global_transform.origin - global_transform.origin)
		if direction.z<0:
			direction.z=0
		_handle_movement(direction.normalized(),delta)
	else:
		_handle_movement(Vector3.ZERO, delta)
			
	var velocity_before_move := velocity
	move_and_slide()
	_handle_collisions(velocity_before_move)

func run_from_bunny(b:VampBunny):
	running_from_bunny=true
	bunny=b
