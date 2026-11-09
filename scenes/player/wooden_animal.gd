extends Node3D

const TURN_DURATION := 0.23
const TURN_HOP_HEIGHT := 0.14
const STEP_HOP_HEIGHT := 0.055
const STEP_ROLL := deg_to_rad(2.0)
const STEP_SMOOTHING := 32.0
const MOVEMENT_THRESHOLD := 0.15
const TAKEOFF_DURATION := 0.24
const TAKEOFF_ROLL := deg_to_rad(5.0)
const APEX_ROLL := deg_to_rad(6.0)
const DESCENT_ROLL := deg_to_rad(3.5)
const APEX_SPEED_RANGE := 3.2
const LANDING_DURATION := 0.32
const LANDING_ROLL := deg_to_rad(5.0)
const LANDING_MIN_SPEED := 2.0
const TOPPLE_DURATION := 0.38
const STAND_DURATION := 0.29
const WOOD_REBOUND_DURATION := 0.16
const WOOD_REBOUND_ANGLE := deg_to_rad(4.0)

@export_range(0.0, 35.0, 0.5) var movement_turn_degrees: float = 18.0
@export_range(1.0, 20.0, 0.5) var turn_smoothing: float = 9.0

@onready var sprite: AnimatedSprite3D = get_node("../AnimatedSprite3D")
@onready var character: AnimalCharacter = get_parent().get_parent() as AnimalCharacter
@onready var facing: Node3D = $Facing
var poses: Array[Node3D] = []

var resting_rotation := Vector3.ZERO
var resting_position := Vector3.ZERO
var topple_pivot := Vector3.ZERO
var topple_progress := 0.0
var rebound_remaining := 0.0
var movement_yaw := 0.0
var turn_progress := 0.0
var step_height := 0.0
var step_roll := 0.0
var was_on_floor := false
var previous_vertical_speed := 0.0
var jump_airborne := false
var takeoff_remaining := 0.0
var landing_remaining := 0.0
var landing_strength := 0.0
var jump_roll := 0.0

func _ready() -> void:
	facing.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	resting_rotation = facing.rotation
	resting_position = facing.position
	turn_progress = 1.0 if sprite.flip_h else 0.0
	for pose: Node3D in facing.get_children():
		poses.append(pose)
	for mesh: MeshInstance3D in poses[0].find_children("*", "MeshInstance3D", true, false):
		var bounds := (facing.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		topple_pivot.z = maxf(topple_pivot.z, maxf(bounds.end.z, -bounds.position.z))
	sprite.hide()
	_sync_visuals()
	_update_facing(0.0)

func _physics_process(_delta: float) -> void:
	var on_floor := character.is_on_floor()
	var vertical_speed := character.velocity.y
	if was_on_floor and not on_floor and vertical_speed > MOVEMENT_THRESHOLD:
		jump_airborne = true
		takeoff_remaining = TAKEOFF_DURATION
		landing_remaining = 0.0
	elif not was_on_floor and on_floor and previous_vertical_speed < -LANDING_MIN_SPEED:
		landing_strength = smoothstep(LANDING_MIN_SPEED, character.jump_velocity, -previous_vertical_speed)
		landing_remaining = LANDING_DURATION
		takeoff_remaining = 0.0
	if on_floor:
		jump_airborne = false
	was_on_floor = on_floor
	previous_vertical_speed = vertical_speed

func _process(delta: float) -> void:
	if sprite.sprite_frames.has_animation("walk"):
		if Vector2(character.velocity.x, character.velocity.z).length() > MOVEMENT_THRESHOLD:
			if not sprite.is_playing():
				sprite.play("walk")
		else:
			sprite.stop()
			sprite.frame = 0
	_update_facing(delta)
	_sync_visuals()

func _update_facing(delta: float) -> void:
	var local_velocity := global_basis.orthonormalized().inverse() * character.velocity
	var movement := Vector2(local_velocity.x, local_velocity.z)
	var speed := movement.length()
	var turn := 0.0
	if speed > MOVEMENT_THRESHOLD:
		var direction := movement.normalized()
		var facing_sign := -1.0 if sprite.flip_h else 1.0
		turn = clampf(direction.x * 0.3 - direction.y * facing_sign, -1.0, 1.0)
	var target_movement_yaw := turn * deg_to_rad(movement_turn_degrees)
	movement_yaw = lerpf(movement_yaw, target_movement_yaw, 1.0 - exp(-turn_smoothing * delta))

	var target_progress := 1.0 if sprite.flip_h else 0.0
	turn_progress = move_toward(turn_progress, target_progress, delta / TURN_DURATION)
	var turn_yaw := PI * smoothstep(0.0, 1.0, turn_progress)
	var turn_arc := _hop_arc(turn_progress)
	_update_walk_step(delta, speed)
	_update_jump_roll(delta)
	var topple := _update_topple(delta)
	var upright := 1.0 - smoothstep(0.0, 0.6, topple_progress)
	var step_weight := 1.0 - turn_arc
	var walk_roll_weight := step_weight * (1.0 - landing_remaining / LANDING_DURATION)
	var rotation := resting_rotation
	rotation.y += turn_yaw + movement_yaw * upright
	rotation.z += (jump_roll + step_roll * walk_roll_weight) * upright
	facing.basis = topple * Basis.from_euler(rotation)
	var hop := (turn_arc * TURN_HOP_HEIGHT + step_height * step_weight) * upright
	facing.position = resting_position + topple_pivot - topple * topple_pivot + Vector3.UP * hop

func _update_topple(delta: float) -> Basis:
	var target := 0.0 if character.is_active_player else 1.0
	var duration := STAND_DURATION if character.is_active_player else TOPPLE_DURATION
	var previous_progress := topple_progress
	if character.is_active_player or character.is_on_floor():
		topple_progress = move_toward(topple_progress, target, delta / duration)
	rebound_remaining = maxf(0.0, rebound_remaining - delta)
	if previous_progress < 1.0 and topple_progress == 1.0:
		rebound_remaining = WOOD_REBOUND_DURATION
	var rebound := WOOD_REBOUND_ANGLE * _hop_arc(rebound_remaining / WOOD_REBOUND_DURATION)
	var angle := (PI * 0.5 - rebound) * pow(topple_progress, 2.3)
	return Basis(Vector3.RIGHT, angle)

func _update_walk_step(delta: float, speed: float) -> void:
	var step_arc := 0.0
	if character.is_on_floor() and sprite.is_playing() and sprite.animation == &"walk":
		step_arc = _hop_arc(sprite.frame_progress) * smoothstep(MOVEMENT_THRESHOLD, character.max_speed, speed)
	var roll_sign := 1.0 if sprite.frame % 2 == 0 else -1.0
	var smoothing := 1.0 - exp(-STEP_SMOOTHING * delta)
	step_height = lerpf(step_height, STEP_HOP_HEIGHT * step_arc, smoothing)
	step_roll = lerpf(step_roll, STEP_ROLL * roll_sign * step_arc, smoothing)

func _update_jump_roll(delta: float) -> void:
	takeoff_remaining = maxf(0.0, takeoff_remaining - delta)
	landing_remaining = maxf(0.0, landing_remaining - delta)
	var takeoff := -TAKEOFF_ROLL * _hop_arc(takeoff_remaining / TAKEOFF_DURATION)
	var landing_decay := landing_remaining / LANDING_DURATION
	var landing := -LANDING_ROLL * landing_strength * sin(TAU * (1.0 - landing_decay)) * landing_decay
	var flight := 0.0
	if jump_airborne:
		var apex_weight := 1.0 - smoothstep(0.0, APEX_SPEED_RANGE, absf(previous_vertical_speed))
		var descent_weight := smoothstep(0.0, APEX_SPEED_RANGE, -previous_vertical_speed)
		flight = APEX_ROLL * apex_weight - DESCENT_ROLL * descent_weight
	jump_roll = lerpf(jump_roll, takeoff + flight + landing, 1.0 - exp(-STEP_SMOOTHING * delta))

func _hop_arc(progress: float) -> float:
	return pow(4.0 * progress * (1.0 - progress), 1.3)

func _sync_visuals() -> void:
	var frame_index := mini(sprite.frame, poses.size() - 1)
	if jump_airborne:
		frame_index = mini(1, poses.size() - 1) if previous_vertical_speed > 0.0 else 0
	if topple_progress > 0.2:
		frame_index = 0
	for index in range(poses.size()):
		poses[index].visible = index == frame_index

