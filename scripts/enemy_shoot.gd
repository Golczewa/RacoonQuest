extends Area3D
@export var speed: float = 14.0
var direction:Vector3


func _physics_process(delta: float) -> void:
	if direction != null and direction != Vector3.ZERO:
		global_position += direction * speed * delta
		
		
func _on_body_entered(body: CharacterBody3D) -> void:
	queue_free()
