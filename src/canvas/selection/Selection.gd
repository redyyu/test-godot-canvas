class_name Selection extends Sprite2D


signal gizmo_hovered(gizmo)
signal gizmo_unhovered(gizmo)
signal gizmo_pressed(gizmo)
signal gizmo_unpressed(gizmo)


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

var selecting_color = Color.WHITE 

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
		gizmo.hovered.connect(_on_gizmo_hovered)
		gizmo.unhovered.connect(_on_gizmo_unhovered)
		gizmo.pressed.connect(_on_gizmo_pressed)
		gizmo.unpressed.connect(_on_gizmo_unpressed)
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
	if points.size() > 1:
		points.pop_back()
	points.append(pos)
	queue_redraw()
	

func selected():
	is_selecting =false
	var rect = get_select_rect(points[0], points[points.size()-1])
	place_gizmos(rect)
	selection_map.clear()
	selection_map.select_rect(rect)
	texture = ImageTexture.create_from_image(selection_map)
	queue_redraw()


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


func _draw():
	if is_selecting and points.size() > 1:
		var rect = get_select_rect(points[0], points[points.size()-1])
		draw_rect(rect, selecting_color, false, 1.0)


# Gizmo

func _on_gizmo_pressed(gizmo):
	gizmo_pressed.emit(gizmo)
	

func _on_gizmo_unpressed(gizmo):
	gizmo_unpressed.emit(gizmo)


func _on_gizmo_hovered(gizmo):
	gizmo_hovered.emit(gizmo)
	

func _on_gizmo_unhovered(gizmo):
	gizmo_unhovered.emit(gizmo)



# selection map

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
