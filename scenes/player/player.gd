class_name Player extends Node3D

@export var starting_animal: AnimalCharacter
@export var camera_offset: Vector3 = Vector3(0, 4, 6)
@export var camera_smooth_speed: float = 8.0

@onready var camera: Camera3D = $Camera3D
@onready var animal_buttons:Array[Node] = $animal_buttons/HBoxContainer.get_children()

const MAX_HEALTH:=5

var active_animal: AnimalCharacter
var health:=MAX_HEALTH
var dead:=false
var animals:Array[AnimalCharacter]

func _ready() -> void:
	var i:=0
	for child in get_children():
		if child is AnimalCharacter:
			animals.append(child)
			animal_buttons[i].pressed.connect(_possess_animal.bind(child))
			animal_buttons[i].text=str(i+1)
			if child.icon:
				animal_buttons[i].icon=child.icon
			child.is_active_player = false
			if active_animal == null and starting_animal == null:
				starting_animal = child
			i+=1
				
	if starting_animal:
		_possess_animal(starting_animal)

func _process(delta: float) -> void:
	if active_animal != null:
		var target_pos := active_animal.get_global_transform_interpolated().origin + camera_offset
		var follow_weight := 1.0 - exp(-camera_smooth_speed * delta)
		camera.global_position = camera.global_position.lerp(target_pos, follow_weight)

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

func get_boar()->AnimalCharacter:
	return get_node_or_null("Boar") as AnimalCharacter

func get_animals()->Array[AnimalCharacter]:
	return animals

func take_dmg(dmg:int)->void:
	health-=dmg
	if health<0:
		dead=true
	print("player took ",dmg," damage")


func _unhandled_input(event: InputEvent) -> void:
	if active_animal == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index:int = event.keycode - KEY_1
		if index >= 0 and index < animals.size():
			_possess_animal(animals[index])