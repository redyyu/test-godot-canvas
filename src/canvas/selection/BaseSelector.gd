class_name BaseSelector extends RefCounted

enum Mode {
	REPLACE,
	ADD,
	SUBTRACT,
	INTERSECTION,
}

enum Pivot {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	MIDDLE_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_CENTER,
	BOTTOM_LEFT,
	MIDDLE_LEFT,
	CENTER,
}

var mode := Mode.REPLACE:
	set(val):
		last_mode = mode
		mode = val

var last_mode := Mode.REPLACE
	
var as_replace :bool :
	get: return mode == Mode.REPLACE
	
var as_subtract :bool :
	get: return mode == Mode.SUBTRACT
	
var as_intersect :bool :
	get: return mode == Mode.INTERSECTION

var selection :Selection
var selected_rect :Rect2i :
	get: 
		if selection:
			return selection.selected_rect
		else:
			return Rect2i(Vector2i.ZERO, Vector2i.ZERO)

var size :Vector2i :
	get: 
		if selection:
			return selection.size
		else:
			return Vector2i.ZERO

var points :PackedVector2Array = []

var is_selecting := false

var opt_as_square := false
var opt_from_center := false


func restore_mode():
	mode = last_mode


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


func resize_to(rsize:Vector2i, rpos:Vector2i, pivot := Pivot.TOP_LEFT):
	if rsize.x > size.x:
		rsize.x = size.x
	if rsize.y > size.y:
		rsize.y = size.y
		
	var rect = Rect2i(selected_rect.position, rsize)
	var velocity = Vector2i(rpos.x - selected_rect.position.x,
							rpos.y - selected_rect.position.y)
			
	match pivot:
		Pivot.TOP_LEFT:
			pass
		Pivot.TOP_CENTER:
			rect.position.x = (selected_rect.position.x + 
				selected_rect.size.x - rect.size.x) / 2
				
		Pivot.TOP_RIGHT:
			rect.position.x = (selected_rect.position.x + 
				selected_rect.size.x - rect.size.x)

		Pivot.MIDDLE_RIGHT:
			rect.position.x = (selected_rect.position.x + 
				selected_rect.size.x - rect.size.x)
			rect.position.y = (selected_rect.position.y + 
				(selected_rect.size.y - rect.size.y) / 2)

		Pivot.BOTTOM_RIGHT:
			rect.position.x = (selected_rect.position.x + 
				selected_rect.size.x - rect.size.x)
			rect.position.y = (selected_rect.position.y + 
				selected_rect.size.y - rect.size.y)

		Pivot.BOTTOM_CENTER:
			rect.position.x = (selected_rect.position.x + 
				(selected_rect.size.x - rect.size.x) / 2 )
			rect.position.y = (selected_rect.position.y + 
				selected_rect.size.y - rect.size.y)

		Pivot.BOTTOM_CENTER:
			rect.position.y = (selected_rect.position.y + 
				selected_rect.size.y - rect.size.y)

		Pivot.MIDDLE_LEFT:
			rect.position.x = (selected_rect.position.x + 
				selected_rect.size.x - rect.size.x)
			rect.position.y = (selected_rect.position.y + 
				(selected_rect.size.y - rect.size.y) / 2)

	selection.resize_selection(rect, velocity)
	

func parse_rectangle_points(sel_points:PackedVector2Array):
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
