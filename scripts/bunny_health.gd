extends Sprite3D

@export var vamp: VampBunny
var damage = 10
@export var max_hp = 100


func _ready() -> void:
	$SubViewport/Panel/ProgressBar.value = max_hp
	
	vamp.less_hp.connect(update)
		

func update():
	$SubViewport/Panel/ProgressBar.value -= damage
	
	if $SubViewport/Panel/ProgressBar.value <= 0:
		print("Enemy died")
		
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
