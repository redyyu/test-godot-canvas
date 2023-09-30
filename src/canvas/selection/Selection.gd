class_name Selection extends Sprite2D

var size := Vector2i.ONE:
	set(val):
		if val >= Vector2i.ONE:
			size = val
			selection_map.crop(size.x, size.y)
#			offset = size / 2  DONT need Sprite2D offset. `centered = false`

var selection_map := SelectionMap.new()
var zoom_ratio := 1.0:
	set(val):
		zoom_ratio = val
		refresh_material()

var points :PackedVector2Array = []


func _ready():
	centered = false
	refresh_material()


func refresh_material():
	material.set_shader_parameter("frequency", zoom_ratio * 50)
	material.set_shader_parameter("width", 1.0 / zoom_ratio)
	queue_redraw()


func get_rect_from_points(pts) -> Rect2i:
	return Rect2i(pts[0], pts[pts.size()-1] - pts[0]).abs()


func update_texture():
	texture = ImageTexture.create_from_image(selection_map)
	queue_redraw()


func deselect():
	points.clear()
	selection_map.select_none()
	texture = null
	


# Eectangle

func selecting_rect(sel_points :Array):
	_current_draw = _draw_rectangle
	points.clear()
	for p in sel_points:
		points.append(p)
	queue_redraw()


func selected_rect(sel_points :Array,
				   replace := false,
				   subtract := false,
				   intersect := false):
	var sel_rect := get_rect_from_points(sel_points)
	selection_map.select_rect(sel_rect, replace, subtract, intersect)
	update_texture()
	points.clear()


# Ellipse

func selecting_ellipse(sel_points :Array):
	_current_draw = _draw_ellipse
	points.clear()
	for p in sel_points:
		points.append(p)
	queue_redraw()


func selected_ellipse(sel_points :Array,
					  replace := false,
					  subtract := false,
					  intersect := false):
	var sel_rect := get_rect_from_points(sel_points)
	selection_map.select_ellipse(sel_rect, replace, subtract, intersect)
	update_texture()
	points.clear()


# Draw selecting lines

func _draw():
	if points.size() <= 1:
		return
	
	_current_draw.call()
	# switch in `selection_` func.
	# try not use state, so many states in proejcts already.
	# also there is internal useage for this class only.


var _current_draw = func():
	pass


var _draw_rectangle = func():
	if points.size() <= 1:
		return
	
	var rect = get_rect_from_points(points)
	if rect.size == Vector2i.ZERO:
		return
	draw_rect(rect, Color.WHITE, false, 1.0 / zoom_ratio)
	# doesn't matter the drawn color, material will take care of it.
	

var _draw_ellipse = func():
	var rect = get_rect_from_points(points)
	if rect.size == Vector2i.ZERO:
		return
	rect = Rect2(rect)
#	draw_rect(rect, Color.WHITE, false, 1.0 / zoom_ratio)
	var radius :float
	var dscale :float
	var center = rect.get_center()
	
	if rect.size.x < rect.size.y:
		radius = rect.size.y / 2.0
		dscale = rect.size.x / rect.size.y
		draw_set_transform(center, 0, Vector2(dscale, 1))
		# the transform is effect whole size 
	else:
		radius = rect.size.x / 2.0
		dscale = rect.size.y / rect.size.x
		draw_set_transform(center, 0, Vector2(1, dscale))
#	draw_rect(Rect2i(Vector2.ZERO, size), Color.WHITE, false, 1.0 / zoom_ratio)
	draw_arc(Vector2.ZERO, radius, 0, 360, 36, Color.WHITE, 1.0 / zoom_ratio)
