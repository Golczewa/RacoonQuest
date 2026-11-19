extends Sprite3D

@export var vamp: VampBunny



func _ready() -> void:
	$SubViewport/Panel/ProgressBar.max_value = vamp.max_hp
	$SubViewport/Panel/ProgressBar.value = vamp.max_hp
	vamp.less_hp.connect(update)
		

func update():
	$SubViewport/Panel/ProgressBar.value =vamp.hp	
