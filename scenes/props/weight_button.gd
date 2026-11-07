extends Node3D

signal correct
signal wrong

@export_enum("low", "medium", "high") var required_weight: String = "medium"

@onready var area: Area3D = $Area3D
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	unpress()


func _on_body_entered(body: Node3D) -> void:
	if body is AnimalCharacter:
		if body.weight_class == required_weight:
			correct.emit()
		else:
			wrong.emit()
		sprite.frame = 3


func _on_body_exited(body: Node3D) -> void:
	if body is AnimalCharacter and area.get_overlapping_bodies().is_empty():
		wrong.emit()
		unpress()


func unpress() -> void:
	match required_weight:
		"low":
			sprite.frame = 0
		"medium":
			sprite.frame = 1
		"high":
			sprite.frame = 2
