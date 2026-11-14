extends Area3D
@export var speed: float = 5.0
var direction:Vector3
var dmg:=1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if direction != null and direction != Vector3.ZERO:
		global_position += direction * speed * delta
		
		
func _on_body_entered(body: Node3D) -> void:
	print("hit")
	var player=get_tree().get_first_node_in_group("player")
	if(body==player.active_animal):
		player.take_dmg(dmg)
		queue_free()

