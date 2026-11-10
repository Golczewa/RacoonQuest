extends CharacterBody3D

class_name Vamp_bunny

@export var player: AnimalCharacter
@export var bullet: StaticBody3D
@export var speed = 30
@onready var shoot = preload("res://scenes/shoot.tscn")


@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
var bunny = self

signal less_hp

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
var main_controller

func _ready() -> void:
	main_controller= get_parent().get_parent()

			

func _on_attack_zone_body_entered(body: Node3D) -> void:
	if body is AnimalCharacter:
		state = ALERT
		shoot_timer.start()

func _on_hitted_area_entered(area: Area3D) -> void:
	if "power" in area:
		less_hp.emit()



	
#func _on_attack_zone_body_exited(body: Node3D) -> void:
	#state = IDLE
	#shoot_timer.stop()
	#target = null
	#player = null

func _physics_process(delta: float) -> void:
	match state:
		ALERT:
			target = main_controller.active_animal
			raycast.look_at(target.global_transform.origin, Vector3.UP)
			raycast.global_transform.origin = global_transform.origin 
			raycast.target_position = Vector3(0,0,-10)
			raycast.force_raycast_update()
			var distance_to_target = global_transform.origin.distance_to(target.global_transform.origin)
			var min_distance = 3.0
			if distance_to_target > min_distance:
				var direction = (target.global_transform.origin - global_transform.origin).normalized()
				if  direction.x > 0:
					animated_sprite_3d.flip_h = true
				elif direction.x < 0:
					animated_sprite_3d.flip_h = false
				var target_velocity = direction * 30 
				velocity.x =  target_velocity.x * delta * 15
				velocity.z = target_velocity.z * delta * 15
				move_and_slide()

				
func _on_shoot_timer_timeout() -> void:
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit is AnimalCharacter:
			var shoot_temp = shoot.instantiate()
			var origin = raycast.global_transform.origin
			var collision_point = raycast.get_collision_point()
			add_child(shoot_temp)
			shoot_temp.global_transform.origin = origin
			var direction = (collision_point - origin).normalized()
			shoot_temp.look_at_from_position(origin + direction, Vector3.UP)
			shoot_temp.get_node("enemy_shoot").direction = direction
			
			
