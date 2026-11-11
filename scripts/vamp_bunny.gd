extends CharacterBody3D

class_name VampBunny

var player: Node3D
@export var speed = 3
@export var shoot_hight: float = 1
@export var max_hp := 10
@export var min_distance: float = 2
@export var max_distance: float = 4

@onready var shoot = preload("res://scenes/shoot.tscn")
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D

signal less_hp
signal correct
signal wrong

enum {
	IDLE,
	ALERT,
}
var acceleration = 15
var target: AnimalCharacter
const TURN_SPEED = 2
@onready var raycast = $RayCast3D
@onready var shoot_timer: Timer = $ShootTimer
@onready var boom_timer: Timer = $BoomTimer
@onready var ring = $MeshInstance3D
@onready var sprite = $AnimatedSprite3D
@onready var shield=$MeshInstance3D2

var state = IDLE
var hp := max_hp
var can_shoot = true
var shot_count := randi_range(4, 6)
var is_ring_active = false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	player.get_boar().run_from_bunny(self)
	state = ALERT


func _physics_process(delta: float) -> void:
	if is_ring_active:
		return
	target = player.active_animal
	raycast.look_at(target.global_transform.origin + Vector3(0, shoot_hight, 0), Vector3.UP)
	raycast.global_transform.origin = global_transform.origin + Vector3(0, shoot_hight, 0)
	raycast.target_position = Vector3(0, 0, -10) + Vector3(0, shoot_hight, 0)
	raycast.force_raycast_update()
	var distance_to_target = global_transform.origin.distance_to(target.global_transform.origin)
	match state:
		ALERT:
			var direction: Vector3
			if distance_to_target < min_distance:
				direction = -(target.global_transform.origin - global_transform.origin).normalized()
				sprite.play("default")
			elif max_distance > distance_to_target and distance_to_target > min_distance:
				direction = Vector3.ZERO
				sprite.stop()
			elif max_distance < distance_to_target:
				sprite.play("default")
				direction = (target.global_transform.origin - global_transform.origin).normalized()
			if direction.x > 0:
				animated_sprite_3d.flip_h = true
			elif direction.x < 0:
				animated_sprite_3d.flip_h = false
			var target_velocity = direction * speed
			if shot_count == 0:
				ring_attack()
			else:
				shoot_attack()
			velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
			velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
			move_and_slide()


func _on_shoot_timer_timeout() -> void:
	can_shoot = true


func take_dmg(dmg: int) -> void:
	if is_ring_active:
		return
	hp -= dmg
	if hp <= 0:
		queue_free()
		correct.emit()
	less_hp.emit()


func shoot_attack() -> void:
	if !can_shoot:
		return
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
			shoot_temp.direction = direction
			can_shoot = false
			shot_count -= 1
			shoot_timer.start()


func ring_attack(attack_time := 5.0) -> void:
	shot_count = randi_range(4, 6)
	is_ring_active = true
	sprite.stop()
	shield.show()
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, attack_time)
	await tween.finished
	sprite.modulate = Color.WHITE
	ring.start(global_position)
	await ring.finished
	shield.hide()
	is_ring_active = false
