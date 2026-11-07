extends Node3D

@onready var tree_pack:PackedScene=preload("res://scenes/props/tree.tscn")

@export var rand_seed:=5
@export var cell_size := 2.0
@export var padding := 0.5 

var generator:=RandomNumberGenerator.new()

func _ready() -> void:
	$MeshInstance3D.hide()
	generator.seed=rand_seed
	call_deferred("spawn_trees")

func spawn_trees() -> void:
	var scale_3d := global_transform.basis.get_scale()
	var size := Vector2(scale_3d.x, scale_3d.z)

	var cells := Vector2i(floori(size.x / cell_size), floori(size.y / cell_size))
	var grid_start := (size - Vector2(cells) * cell_size) / 2.0 - size / 2.0

	for cx in cells.x:
		for cz in cells.y:
			var meters := grid_start + Vector2(cx, cz) * cell_size
			meters.x += generator.randf_range(padding, cell_size - padding)
			meters.y += generator.randf_range(padding, cell_size - padding)
			var local_point := Vector3(meters.x / size.x, 0.0, meters.y / size.y)

			var tree: Node3D = tree_pack.instantiate()
			get_parent().add_child(tree)
			tree.global_position = to_global(local_point)
			tree.rotation.y = generator.randf_range(0.0, TAU)