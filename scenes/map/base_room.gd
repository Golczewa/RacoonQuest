extends Node3D
class_name Room

@export var spawns:Array[Marker3D]
@export var exit:Area3D
var level:Level

func _ready() -> void:
	level=get_parent()
	exit.body_entered.connect(on_body_entered)

func on_body_entered(body:Node3D):
	if body is AnimalCharacter:
		level.call_deferred("next_room")
