extends CharacterBody3D
@onready var nav_agent = $"../NavigationAgent3D"
var player: Player
@export var speed = 30
@onready var shoot = preload("res://scenes/shoot.tscn")
enum {
	IDLE,
	ALERT,
}
var velocity2 = Vector3.ZERO
var target 
const TURN_SPEED = 2
@onready var raycast = $"../RayCast3D"
@onready var shoot_timer: Timer = $"../ShootTimer"
var state = IDLE
func _ready() -> void:
	pass
func update_target_location(target_location):
	nav_agent.set_target_location(target_location)
func _on_attack_zone_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body
		state = ALERT
		target = body
		shoot_timer.start()
func _on_attack_zone_body_exited(_body: Node3D) -> void:
	state = IDLE
	shoot_timer.stop()
	target = null
	player = null
func _physics_process(delta: float) -> void:
	var current_location = global_transform.origin
	var direction = (next_location - current_location)
	
	if direction.length() > 0.1:
		direction = direction.normalized()
	else:
		direction = Vector3.ZERO
	match state:
		ALERT:
			if target:
				raycast.look_at(target.global_transform.origin, Vector3.UP)
				raycast.global_transform.origin = global_transform.origin 
				raycast.target_position = Vector3(0, 0, -10)
				raycast.force_raycast_update()
				var distance_to_target = global_transform.origin.distance_to(target.global_transform.origin)
				var min_distance = 3.0
				if distance_to_target > min_distance:
					velocity = direction * speed
				else:
					velocity = Vector3.ZERO
			else:
				velocity = Vector3.ZERO
		IDLE:
			velocity = Vector3.ZERO
	velocity2 = move_and_slide()
func _on_shoot_timer_timeout() -> void:
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit is Player:
			var shoot_temp = shoot.instantiate()
			var origin = raycast.global_transform.origin
			var collision_point = raycast.get_collision_point()
			add_child(shoot_temp)
			shoot_temp.global_transform.origin = origin
			var direction = (collision_point - origin).normalized()
			shoot_temp.look_at_from_position(origin + direction, Vector3.UP)
			shoot_temp.get_node("enemy_shoot").direction = direction
