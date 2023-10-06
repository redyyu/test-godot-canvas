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
			return -1

var as_replace :bool :
	get: return mode == Selection.Mode.REPLACE

var as_add :bool :
	get: return mode == Selection.Mode.ADD
	
var as_subtract :bool :
	get: return mode == Selection.Mode.SUBTRACT
	
var as_intersect :bool :
	get: return mode == Selection.Mode.INTERSECTION

var opt_as_square := false
var opt_from_center := false

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



func parse_rectangle_points(sel_points:PackedVector2Array):
	if sel_points.size() < 2:
		# skip parse if points is not up to 2.
		# the _draw() will take off the rest.
		return sel_points
		
	var pts :PackedVector2Array = []
	var start := sel_points[0]
	var end := sel_points[1]
	var sel_size := (start - end).abs()
	
	if opt_as_square:
		# Make rect 1:1 while centering it on the mouse
		var square_size :float = max(sel_size.x, sel_size.y)
		sel_size = Vector2(square_size, square_size)
		end = start - sel_size if start > end else start + sel_size

	if opt_from_center:
		var _start = Vector2(start.x, start.y)
		if start.x < end.x:
			start.x -= sel_size.x
			end.x += 2 * sel_size.x
		else:
			_start.x = end.x - 2 * sel_size.x
			end.x = start.x + sel_size.x
			start.x = _start.x
			
		if start.y < end.y:
			start.y -= sel_size.y
			end.y += 2 * sel_size.y
		else:
			_start.y = end.y - 2 * sel_size.y
			end.y = start.y + sel_size.y
			start.y = _start.y
			

	pts.append(start)
	pts.append(end)
	return pts
