extends StaticBody3D

signal correct
signal wrong

func shatter()->void:
	correct.emit()
	queue_free()
