class_name BaseSelector extends RefCounted

signal updated(rect, rel_pos, status)
signal canceled(rect, rel_pos)

var selection :Selection:
	set = set_selection
	
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
	set(val):
		if selection:
			selection.mode = val

var points :PackedVector2Array = []

var is_selecting := false
var is_moving := false

var is_operating :bool :
	get: return is_selecting or is_moving

var opt_from_center :bool :
	get: 
		if selection:
			return selection.opt_from_center
		else:
			return false
	set(val):
		if selection:
			selection.opt_from_center = val

var opt_as_square :bool :
	get: 
		if selection:
			return selection.opt_as_square
		else:
			return false
	set(val):
		if selection:
			selection.opt_as_square = val
	

func set_selection(val):
	if val and selection != val:
		if selection:
			if selection.updated.is_connected(_on_updated):
				selection.updated.disconnect(_on_updated)
			if selection.canceled.is_connected(_on_canceled):
				selection.canceled.disconnect(_on_canceled)
		selection = val
		selection.updated.connect(_on_updated)
		selection.canceled.connect(_on_canceled)


func set_pivot(pivot_id):
	if selection:
		selection.set_pivot(pivot_id)


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


func _on_updated(rect, rel_pos):
	updated.emit(rect, rel_pos, true)
	
func _on_canceled(rect, rel_pos):
	canceled.emit(rect, rel_pos)

