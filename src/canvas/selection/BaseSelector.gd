class_name BaseSelector extends RefCounted


var selection :Selection
var selected_rect :Rect2i :
	get: 
		if selection:
			return selection.selected_rect
		else:
			return Rect2i()

var size :Vector2i :
	get: 
		if selection:
			return selection.size
		else:
			return Vector2i.ZERO

var mode :Selection.Mode:
	get: 
		if selection:
			return selection.mode
		else:
			return Selection.Mode.REPLACE

var points :PackedVector2Array = []

var is_selecting := false
var is_moving := false

var is_operating :bool :
	get: return is_selecting or is_moving


func reset():
	points.clear()
	is_selecting = false
	is_moving = false


func select_start(_pos :Vector2i):
	pass
	


func select_move(pos :Vector2i):
	if not is_operating:
		select_start(pos)
	

func select_end(_pos :Vector2i):
	is_selecting = false
	is_moving = false

