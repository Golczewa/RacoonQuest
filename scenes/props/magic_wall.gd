extends StaticBody3D

@export var triggers:Array[Node3D]

var conditions:Array[bool]=[] 

func _ready() -> void:
	for i in range(triggers.size()-1):
		conditions.append(false)
		triggers[i].correct.connect("change_to_true").bind(i)	

func change_to_true(i:int)->void:
	conditions[i]=true
	if check_if_solved():
		queue_free()

func change_to_false(i:int)->void:
	conditions[i]=false

func check_if_solved()->bool:
	var result=true
	for cond in conditions:
		result=result and cond
	return result


