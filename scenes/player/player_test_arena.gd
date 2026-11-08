extends Node3D

@export var starting_animal: AnimalCharacter
@export var camera_offset: Vector3 = Vector3(0, 4, 6)
@export var camera_smooth_speed: float = 8.0

@onready var camera: Camera3D = $Camera3D

var active_animal: AnimalCharacter
	
func _ready() -> void:
	for child in get_children():
		if child is AnimalCharacter:
			child.is_active_player = false
			if active_animal == null and starting_animal == null:
				starting_animal = child
				
	if starting_animal:
		_possess_animal(starting_animal)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_character") and active_animal != null:
		var target_animal := active_animal.get_closest_swappable_animal()
		if target_animal != null:
			_possess_animal(target_animal)
		else:
			print("Come closer to another animal.")
			
	if active_animal != null:
		var target_pos := active_animal.global_position + camera_offset
		camera.global_position = camera.global_position.lerp(target_pos, camera_smooth_speed * delta)

func _possess_animal(new_animal: AnimalCharacter) -> void:
	var transferred_velocity := Vector3.ZERO
	if active_animal != null:
		transferred_velocity = Vector3(active_animal.velocity.x, 0.0, active_animal.velocity.z)
		active_animal.velocity = Vector3(0.0, active_animal.velocity.y, 0.0)
		active_animal.is_active_player = false

	active_animal = new_animal
	active_animal.is_active_player = true

	if transferred_velocity.length() > 0.1:
		active_animal.velocity.x = transferred_velocity.x
		active_animal.velocity.z = transferred_velocity.z

	print("Body taken: ", active_animal.name)

func get_boar_rid()->RID:
	return $animals/Boar/CollisionShape3D.get_rid()