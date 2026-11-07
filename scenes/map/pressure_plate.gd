extends Area3D

signal activated
signal deactivated

@export var required_weight: float = 1.0 
@export var is_trap: bool = false

var is_pressed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_changed)
	body_exited.connect(_on_body_changed)

func _on_body_changed(_body: Node3D) -> void:
	var current_weight: float = 0.0
	for body in get_overlapping_bodies():
		if body is AnimalCharacter:
			current_weight += body.weight
		elif body is RigidBody3D:
			current_weight += body.mass
			
	var should_be_pressed := current_weight >= required_weight
	if should_be_pressed and not is_pressed:
		is_pressed = true
		activated.emit()
		print("Pressure plate pressed. Weight: ", current_weight)
		if is_trap:
			print("Trap activated.")
	elif not should_be_pressed and is_pressed:
		is_pressed = false
		deactivated.emit()
		print("Pressure plate released.")
