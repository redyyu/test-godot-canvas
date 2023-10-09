class_name ShapingArea extends Node2D

signal updated(rect, rel_pos)
signal canceled


var pivot := Pivot.TOP_LEFT  # Pivot class in /core.
var pivot_offset :Vector2i :
	get: return get_pivot_offset(shaped_rect.size)

var relative_position :Vector2i :  # with pivot, for display on panel
	get: return shaped_rect.position + pivot_offset

var shaped_map := Image.new()
var shaped_rect := Rect2i(Vector2i.ZERO, Vector2i.ZERO)
var boundary := Rect2i(Vector2i.ZERO, Vector2i.ZERO)
var shape_color := Color.BLACK

var zoom_ratio := 1.0

var points :PackedVector2Array = []

var opt_as_square := false
var opt_from_center := false

var is_pressed := false


func reset():
	_current_shape = null
	points.clear()
	shaped_map.fill(Color.TRANSPARENT)


func update_shaping():
	if shaped_map.is_invisible():
		shaped_rect = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
		canceled.emit(shaped_rect, relative_position)
	else:
		shaped_rect = get_rect_from_points(points)
		updated.emit(shaped_rect, relative_position)
			
	_current_shape = null
	queue_redraw()


func get_rect_from_points(pts) -> Rect2i:
	if pts.size() < 1:
		return Rect2i()
	return Rect2i(pts[0], pts[pts.size() - 1] - pts[0]).abs()


func check_visible(sel_points) -> bool:
	visible = true if sel_points.size() > 1 else false
	# less 2 points is needed,
	# because require 2 points to make 1 pixel.
	return visible
	

func get_pivot_offset(to_size:Vector2i) -> Vector2i:
	var _offset = Vector2i.ZERO
	match pivot:
		Pivot.TOP_LEFT:
			pass
			
		Pivot.TOP_CENTER:
			_offset.x = to_size.x / 2.0

		Pivot.TOP_RIGHT:
			_offset.x = to_size.x

		Pivot.MIDDLE_RIGHT:
			_offset.x = to_size.x
			_offset.y = to_size.y / 2.0

		Pivot.BOTTOM_RIGHT:
			_offset.x = to_size.x
			_offset.y = to_size.y

		Pivot.BOTTOM_CENTER:
			_offset.x = to_size.x / 2.0
			_offset.y = to_size.y

		Pivot.BOTTOM_LEFT:
			_offset.y = to_size.y

		Pivot.MIDDLE_LEFT:
			_offset.y = to_size.y / 2.0
		
		Pivot.CENTER:
			_offset.x = to_size.x / 2.0
			_offset.y = to_size.y / 2.0
			
	return _offset


func parse_two_points(sel_points:PackedVector2Array):
	if sel_points.size() < 2:
		# skip parse if points is not up to 2.
		# the _draw() will take off the rest.
		return sel_points
		
	var pts :PackedVector2Array = []
	var start := sel_points[0]
	var end := sel_points[sel_points.size() - 1]
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



# Rectangle

func shaping_rectangle(sel_points :Array):
	sel_points = parse_two_points(sel_points)
	if not check_visible(sel_points):
		return
	_current_shape = _shape_rectangle
	points = sel_points
	queue_redraw()


func shaped_rectangle(sel_points :Array):
	sel_points = parse_two_points(sel_points)
	if not check_visible(sel_points):
		return
	var _rect := get_rect_from_points(sel_points)
	if _rect.size < Vector2i.ONE:
		return
	shaped_map.fill_rect(_rect, shape_color)
	points.clear()
	update_shaping()


# Ellipse

func selecting_ellipse(sel_points :Array):
	sel_points = parse_two_points(sel_points)
	if not check_visible(sel_points):
		return
	_current_shape = _shape_ellipse
	points = sel_points
	queue_redraw()


func selected_ellipse(sel_points :Array):
	sel_points = parse_two_points(sel_points)
	if not check_visible(sel_points):
		return
	var _rect := get_rect_from_points(sel_points)
	if _rect.size < Vector2i.ONE:
		return
	shaped_map.shape_ellipse(_rect, shape_color)
	points.clear()
	update_shaping()


# Polygon

func selecting_polygon(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_shape = _shape_polyline
	points = sel_points
	queue_redraw()


func selected_polygon(sel_points :Array):
	if not check_visible(sel_points):
		return
	shaped_map.shape_polygon(sel_points, shape_color)
	points.clear()
	update_shaping()


# Draw selecting lines

func _draw():
	if points.size() > 1:
		if _current_shape is Callable:
			_current_shape.call()
		# switch in `selection_` func.
		# try not use state, so many states in proejcts already.
		# also there is internal useage for this class only.

var _current_shape = null


var _shape_rectangle = func():
	if points.size() <= 1:
		return
	
	var rect = get_rect_from_points(points)
	if rect.size == Vector2i.ZERO:
		return
	draw_rect(rect, Color.WHITE, false, 1.0 / zoom_ratio)
	# doesn't matter the drawn color, material will take care of it.
	

var _shape_ellipse = func():
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


var _shape_polyline = func():
	draw_polyline(points, Color.WHITE, 1 / zoom_ratio)
	

func _input(event):
	if event is InputEventKey:
		var delta := 1
		
		if Input.is_key_pressed(KEY_ESCAPE):
			reset()
		
		if Input.is_key_pressed(KEY_SHIFT):
			delta = 10
			
		if Input.is_action_pressed('ui_up'):
			if shaped_rect.position.y < delta:
				delta = shaped_rect.position.y
			move_delta(-delta, VERTICAL)
		
		elif Input.is_action_pressed('ui_right'):
			var right_remain := boundary.size.x - shaped_rect.end.x
			if right_remain < delta:
				delta = right_remain
			move_delta(delta, HORIZONTAL)
		
		elif Input.is_action_pressed('ui_down'):
			var bottom_remain := boundary.size.y - shaped_rect.end.y
			if bottom_remain < delta:
				delta = bottom_remain
			move_delta(delta, VERTICAL)
		
		elif Input.is_action_pressed('ui_left'):
			if shaped_rect.position.x < delta:
				delta = shaped_rect.position.x
			move_delta(-delta, HORIZONTAL)

