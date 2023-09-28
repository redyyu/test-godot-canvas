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
		refresh_selection()

var points :Array[Vector2] = []
var gizmos :Array[Gizmo]= []

var is_selecting := false

var opt_as_square := false
var opt_from_center := false


func _ready():
	refresh_selection()
	gizmos.append(Gizmo.new(Gizmo.TOP_LEFT))
	gizmos.append(Gizmo.new(Gizmo.TOP_CENTER))
	gizmos.append(Gizmo.new(Gizmo.TOP_RIGHT))
	gizmos.append(Gizmo.new(Gizmo.MIDDLE_RIGHT))
	gizmos.append(Gizmo.new(Gizmo.BOTTOM_RIGHT))
	gizmos.append(Gizmo.new(Gizmo.BOTTOM_CENTER))
	gizmos.append(Gizmo.new(Gizmo.BOTTOM_LEFT))
	gizmos.append(Gizmo.new(Gizmo.MIDDLE_LEFT))
	for gizmo in gizmos:
		add_child(gizmo)


func refresh_selection():
	material.set_shader_parameter("frequency", zoom_ratio * 50)
	material.set_shader_parameter("width", 1.0 / zoom_ratio)
	for gizmo in gizmos:
		gizmo.zoom_ratio = zoom_ratio
	

func place_gizmos(rect: Rect2i):
	for gizmo in gizmos:
		gizmo.place(rect)
	

func deselect():
	points.clear()
	selection_map.clear()
	is_selecting = false
	texture = null
	
	for gizmo in gizmos:
		gizmo.dismiss()
	

func selecting(pos):
	is_selecting = true
	if points.size() >= 2:
		points.pop_back()
	points.append(pos)
	var rect = get_select_rect(points[0], points[points.size()-1])
	place_gizmos(rect)
	selection_map.clear()
	selection_map.select_rect(rect)
	texture = ImageTexture.create_from_image(selection_map)


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
	
	extends ColorRect
	
	enum {
		TOP_LEFT,
		TOP_CENTER,
		TOP_RIGHT,
		MIDDLE_RIGHT,
		BOTTOM_RIGHT,
		BOTTOM_CENTER,
		BOTTOM_LEFT,
		MIDDLE_LEFT,
	}
	
	var direction := TOP_LEFT
	var default_size := Vector2(10, 10)
	var gizmo_color := Color(0.2, 0.2, 0.2, 1)
	var gizmo_size :Vector2 :
		get: return default_size / zoom_ratio
	var gizmo_rect :Rect2i
	var saved_pos: Vector2
	var zoom_ratio := 1.0:
		set(val):
			zoom_ratio = val
			scale = Vector2.ONE / val 
	
	var cursor := Control.CURSOR_ARROW

	func dismiss():
		visible = false
		
	func place(rect :Rect2i):
		if not rect:
			return

		gizmo_rect = rect

		visible = true
		
		var gpos = rect.position
		var gsize = rect.size
		
		match direction:
			TOP_LEFT: 
				position = gpos + Vector2i.ZERO
			TOP_CENTER: 
				position = gpos + Vector2i(gsize.x / 2, 0)
			TOP_RIGHT: 
				position = gpos + Vector2i(gsize.x, 0)
			MIDDLE_RIGHT:
				position = gpos + Vector2i(gsize.x, gsize.y /2)
			BOTTOM_RIGHT:
				position = gpos + Vector2i(gsize.x, gsize.y)
			BOTTOM_CENTER:
				position = gpos + Vector2i(gsize.x / 2, gsize.y)
			BOTTOM_LEFT:
				position = gpos + Vector2i(0, gsize.y)
			MIDDLE_LEFT:
				position = gpos + Vector2i(0, gsize.y / 2)
			
		saved_pos = position
		position -= gizmo_size / 2


#	func _draw():
#		draw_rect(Rect2(-gizmo_size/2, gizmo_size), gizmo_color)

	func _on_mouse_over():
		print('fuck')
	
	
	func _init(_direction):
		visible = false
		direction = _direction
		size = gizmo_size
		color = gizmo_color
		pivot_offset = gizmo_size / 2
		mouse_entered.connect(_on_mouse_over)
		
		match direction:
			TOP_LEFT:
				cursor = Control.CURSOR_FDIAGSIZE
			TOP_CENTER:
				cursor = Control.CURSOR_VSIZE
			TOP_RIGHT:
				cursor = Control.CURSOR_BDIAGSIZE
			MIDDLE_RIGHT:
				cursor = Control.CURSOR_HSIZE
			BOTTOM_RIGHT:
				cursor = Control.CURSOR_FDIAGSIZE
			BOTTOM_CENTER:
				cursor = Control.CURSOR_VSIZE
			BOTTOM_LEFT:
				cursor = Control.CURSOR_BDIAGSIZE
			MIDDLE_LEFT:
				cursor = Control.CURSOR_HSIZE
			_:
				cursor = Control.CURSOR_POINTING_HAND
