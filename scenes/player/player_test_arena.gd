extends Node3D

@export var animals: Array[AnimalCharacter] = []
@export var camera_offset: Vector3 = Vector3(3.5, 4, 6)
@export var camera_smooth_speed: float = 8.0

@onready var camera: Camera3D = $Camera3D

var current_index: int = 0

func _ready() -> void:
	if animals.is_empty():
		for child in get_children():
			if child is AnimalCharacter:
				animals.append(child)
	
	_update_active_animal()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_character") and animals.size() > 1:
		current_index = (current_index + 1) % animals.size()
		_update_active_animal()
		
	if not animals.is_empty():
		var target_pos := animals[current_index].global_position + camera_offset
		camera.global_position = camera.global_position.lerp(target_pos, camera_smooth_speed * delta)

func _update_active_animal() -> void:
	for i in range(animals.size()):
		animals[i].is_active_player = (i == current_index)
