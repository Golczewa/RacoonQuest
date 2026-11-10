extends Node3D
class_name Level


@export var rooms:Array[PackedScene]

var animals:Array[Node]
var curr_room:Room
var curr_room_num:=0

func _ready() -> void:
	animals=get_tree().get_first_node_in_group("player").get_animals()
	first_room()



func next_room()->void:
	if(curr_room_num+1>=rooms.size()):
		return
	print("changing room to",str(curr_room_num+1))
	curr_room_num+=1
	curr_room.queue_free()
	curr_room=rooms[curr_room_num].instantiate()
	add_child(curr_room)
	for i in animals.size():
		animals[i].global_position=curr_room.spawns[i].global_position


func first_room()->void:
	curr_room=rooms[curr_room_num].instantiate()
	add_child(curr_room)
	for i in animals.size():
		animals[i].global_position=curr_room.spawns[i].global_position
