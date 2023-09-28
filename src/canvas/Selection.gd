class_name Selection extends Sprite2D

var size := Vector2i.ZERO:
	set(val):
		size = val
		selection_map.crop(size.x, size.y)
		offset = size / 2
		
var selection_map := SelectionMap.new()
var zoom_ratio := 1.0:
	set(val):
		zoom_ratio = val
		refresh_ants()

var selecting := false
var points :Array[Vector2] = []

var opt_as_square := false
var opt_from_center := false


func _init():
	refresh_ants()
	
	
func refresh_ants():
	material.set_shader_parameter("frequency", zoom_ratio * 50)
	material.set_shader_parameter("width", 1.0 / zoom_ratio)


func reset():
	points.clear()
	selection_map.clear()
	texture = null


func select_start(pos):
	reset()
	points.append(pos)
	selecting = true


func select_move(pos):
	if not selecting:
		select_start(pos)
	if points.size() >= 2:
		points.pop_back()
	points.append(pos)
	var rect = get_select_rect(points[0], points[points.size()-1])
	selection_map.clear()
	selection_map.select_rect(rect)
	texture = ImageTexture.create_from_image(selection_map)


func select_end(_pos):
	selecting = false
		

func get_select_rect(start :Vector2i, end :Vector2i) -> Rect2i:
	var rect := Rect2i()

	# Center the rect on the mouse
	if opt_from_center:
		var sel_size := end - start
		
		if opt_as_square:  # Make rect 1:1 while centering it on the mouse
			var square_size := maxi(absi(sel_size.x), absi(sel_size.y))
			sel_size = Vector2i(square_size, square_size)

		start -= sel_size
		end = start + 2 * sel_size

	# Make rect 1:1 while not trying to center it
	if opt_as_square:
		var square_size := mini(absi(start.x - end.x), absi(start.y - end.y))
		rect.position.x = start.x if start.x < end.x else start.x - square_size
		rect.position.y = start.y if start.y < end.y else start.y - square_size
		rect.size = Vector2i(square_size, square_size)
	# Get the rect without any modifications
	else:
		rect.position = Vector2i(mini(start.x, end.x), mini(start.y, end.y))
		rect.size = (start - end).abs()

	rect.size += Vector2i.ONE

	return rect


class SelectionMap extends Image:
	const SELECTED_COLOR = Color(1, 1, 1, 1)
	const UNSELECTED_COLOR = Color(0)
	
	var width :int:
		set(val):
			crop(val, maxi(get_height(), 1))
		get: return get_width()
	
	var height :int:
		set(val):
			crop(maxi(get_width(), 1), val)
		get: return get_height()
	
	
	func _init():
		var img = Image.create(1,1,false, FORMAT_LA8)
		copy_from(img)

	
	func is_selected(pos: Vector2i) -> bool:
		if pos.x < 0 or pos.y < 0 or pos.x >= width or pos.y >= height:
			return false
		return get_pixelv(pos).a > 0
	
	
	func select_rect(rect, select := true):
		if select:
			fill_rect(rect, SELECTED_COLOR)
		else:
			fill_rect(rect, UNSELECTED_COLOR)
			
	
	func select_pixel(pos :Vector2i, select := true):
		if select:
			set_pixelv(pos, SELECTED_COLOR)
		else:
			set_pixelv(pos, UNSELECTED_COLOR)
	
	
	func select_all() -> void:
		fill(SELECTED_COLOR)


	func clear() -> void:
		fill(UNSELECTED_COLOR)



class Gizmo:
	
	extends Control
	
	const SIZE := Vector2(6, 6) 
	var rect := Rect2(-SIZE/2, SIZE)
	var direction := Vector2i.ZERO

	func _init(_direction := Vector2i.ZERO):
		direction = _direction

		if direction == Vector2i.ZERO:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		elif direction == Vector2i(-1, -1) or direction == Vector2i(1, 1):
			# Top left or bottom right:
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		elif direction == Vector2i(1, -1) or direction == Vector2i(-1, 1):
			# Top right or bottom left
			mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		elif direction == Vector2i(0, -1) or direction == Vector2i(0, 1):
			# Center top or center bottom
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
		elif direction == Vector2i(-1, 0) or direction == Vector2i(1, 0):
			# Center left or center right
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		else:
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			
