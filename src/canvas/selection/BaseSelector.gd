class_name BaseSelector extends RefCounted

var selection :Selection
var selected_rect :Rect2i :
	get: return selection.selected_rect

var size :Vector2i :
	get: return selection.size

var mode :Selection.Mode:
	get: return selection.mode

var points :PackedVector2Array = []
var drag_offset := Vector2i.ZERO

var is_selecting := false
var is_moving := false

var is_operating :bool :
	get: return is_selecting or is_moving


func _init(sel :Selection):
	selection = sel


func reset():
	drag_offset = Vector2i.ZERO
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
