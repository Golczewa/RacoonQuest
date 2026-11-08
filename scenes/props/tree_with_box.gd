extends StaticBody3D

@export var box_scene: PackedScene = preload("res://scenes/props/box.tscn")
@onready var box_sprite: Sprite3D = $Sprite3D/Sprite3D
@onready var drop_zone: Area3D = $DropZone

var box_dropped: bool = false

func _ready() -> void:
	drop_zone.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if box_dropped:
		return
	if body is AnimalCharacter:
		box_dropped = true
		box_sprite.visible = false
		_spawn_falling_box.call_deferred()

func _spawn_falling_box() -> void:
	var box := box_scene.instantiate() as RigidBody3D
	get_parent().add_child(box)
	box.global_position = global_position + Vector3(1.8, 5.0, 0.0)
