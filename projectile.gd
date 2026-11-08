extends Area3D

@export var speed: float = 14.0
@export var lifetime: float = 2.5

var direction: Vector3 = Vector3.FORWARD
var shooter: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body == shooter:
		return
	if body.is_in_group("shotable"):
		body.shatter()
	print("Projectile hit: ", body.name)
	queue_free()
