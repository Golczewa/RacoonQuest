extends Sprite3D

signal no_hp_left

@export var max_hp = 100

func _ready() -> void:
	$SubViewport/Panel/ProgressBar.max_value = max_hp
	$SubViewport/Panel/ProgressBar.value = max_hp


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
