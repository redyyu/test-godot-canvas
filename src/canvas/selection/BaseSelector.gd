class_name BaseSelector extends RefCounted


var selection :Selection

var points :PackedVector2Array = []

var is_selecting := false

var opt_as_square := false
var opt_from_center := false


func reset():
	points.clear()
	is_selecting = false


func select_start(pos :Vector2i):
	reset()
	is_selecting = true
	points.append(pos)


func select_move(pos :Vector2i):
	if not is_selecting:
		select_start(pos)
	

func select_end(_pos :Vector2i):
	is_selecting = false
