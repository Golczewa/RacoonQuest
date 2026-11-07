extends Area3D
@export var speed: float = 30
var direction:Vector3

func _physics_process(delta: float) -> void:
	if direction != null and direction != Vector3.ZERO:
		global_translate(direction * speed * delta)
