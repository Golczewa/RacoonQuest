extends CharacterBody3D
var player:Player

@export var speed = 30
@onready var shoot = preload("res://scenes/shoot.tscn")


enum {
	IDLE,
	ALERT,
}
var acceleration = 15
var target 
const TURN_SPEED = 2
@onready var raycast = $RayCast3D
@onready var shoot_timer: Timer = $ShootTimer
@onready var boom_timer: Timer = $BoomTimer

var state = IDLE
func _ready() -> void:
	pass

func _on_attack_zone_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body
		state = ALERT
		target = body
		shoot_timer.start()
	
func _on_attack_zone_body_exited(body: Node3D) -> void:
	state = IDLE
	shoot_timer.stop()
	target = null
	player = null

func _physics_process(delta: float) -> void:


	
	match state:
		ALERT:
			raycast.look_at(target.global_transform.origin, Vector3.UP)
			raycast.global_transform.origin = global_transform.origin 
			raycast.target_position = Vector3(0,0,-10)
			raycast.force_raycast_update()
			var distance_to_target = global_transform.origin.distance_to(target.global_transform.origin)
			var min_distance = 3.0
			if distance_to_target > min_distance:
				var direction = (target.global_transform.origin - global_transform.origin).normalized()
				var target_velocity = direction * speed
				velocity.x =  target_velocity.x * delta * 7
				velocity.z = target_velocity.z * delta * 7
				move_and_slide()

				
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
			
			
func _on_boom_timer_timeout() -> void:
	shoot_timer.stop()
	if raycast.is_colliding:
		var boom = raycast.get_collider()
	
	
