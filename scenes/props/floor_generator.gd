extends Node3D

@export var rand_seed:=5
@export var stuff_count:=10
@export var stuff:Array[PackedScene]=[]

var generator:=RandomNumberGenerator.new()

func _ready() -> void:
	$MeshInstance3D.hide()
	generator.seed=rand_seed
	call_deferred("gerate")
	

func gerate()->void:
	for i in range(stuff_count):
		var prop:Node3D=stuff[generator.randi_range(0,stuff.size()-1)].instantiate()
		get_parent().add_child(prop)
		prop.global_position=get_random_point()


func get_random_point() -> Vector3:
	var local_point := Vector3(generator.randf_range(-0.5, 0.5), 0.0, generator.randf_range(-0.5, 0.5))
	return to_global(local_point)
