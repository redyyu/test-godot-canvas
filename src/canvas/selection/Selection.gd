class_name Selection extends Sprite2D


signal updated(rect, rel_pos)
signal canceled


enum Mode {
	REPLACE,
	ADD,
	SUBTRACT,
	INTERSECTION,
}

var mode := Mode.REPLACE

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

var pivot := Pivot.TOP_LEFT
var pivot_offset :Vector2i :
	get: return get_pivot_offset(selected_rect.size)
	
var relative_position :Vector2i :  # with pivot, for display on panel
	get: return selected_rect.position + pivot_offset


var size := Vector2i.ONE:
	set(val):
		if val >= Vector2i.ONE:
			size = val
			selection_map.crop(size.x, size.y)
#			offset = size / 2  DONT need Sprite2D offset. `centered = false`

var selection_map := SelectionMap.new(size.x, size.y)
var selected_rect := Rect2i(Vector2i.ZERO, Vector2i.ZERO)

var mask :SelectionMap :
	get: return selection_map

var zoom_ratio := 1.0 :
	set(val):
		zoom_ratio = val
		refresh_material()

var points :PackedVector2Array = []

var opt_as_square := false
var opt_from_center := false

var as_replace :bool :
	get: return mode == Selection.Mode.REPLACE

var as_add :bool :
	get: return mode == Selection.Mode.ADD
	
var as_subtract :bool :
	get: return mode == Selection.Mode.SUBTRACT
	
var as_intersect :bool :
	get: return mode == Selection.Mode.INTERSECTION

var is_pressed := false


# DO IT on stage.
#var marching_ants_outline := preload('MarchingAntsOutline.gdshader')
#func _init():
#	var shader_material = ShaderMaterial.new()
#	shader_material.shader = marching_ants_outline
#	material = shader_material


func _ready():
	visible = false
	centered = false
	refresh_material()


func refresh_material():
	material.set_shader_parameter("frequency", zoom_ratio * 50)
	material.set_shader_parameter("width", 1.0 / zoom_ratio)
	queue_redraw()


func set_pivot(pivot_id):
	pivot = pivot_id
	if selected_rect.has_area():
		updated.emit(selected_rect, relative_position)


func update_selection(muted := false):
	if selection_map.is_invisible():
		texture = null
		selected_rect = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
		if not muted:
			canceled.emit()
	else:
		texture = ImageTexture.create_from_image(selection_map)
		selected_rect = selection_map.get_used_rect()
		if not muted:
			updated.emit(selected_rect, relative_position)
			
	_current_draw = _draw_nothing
	queue_redraw()


func has_selected() -> bool:
	return selected_rect.has_area()


func has_point(point :Vector2i, precisely := false) -> bool:
	if has_selected() and selected_rect.has_point(point):
		if precisely:
			return selection_map.is_selected(point)
		else:
			return true
	else:
		return false


func deselect(muted := false):
	points.clear()
	selection_map.select_none()
	_current_draw = _draw_nothing
	update_selection(muted)


func move_to(to_pos :Vector2i, use_pivot := true):
	var _offset := pivot_offset if use_pivot else Vector2i.ZERO
		
	var target_pos := to_pos - _offset
	var target_edge := target_pos + selected_rect.size
	if target_pos.x < 0:
		to_pos.x = _offset.x
	if target_pos.y < 0:
		to_pos.y = _offset.y
	if target_edge.x > size.x:
		to_pos.x -= target_edge.x - size.x
	if target_edge.y > size.y:
		to_pos.y -= target_edge.y - size.y
		
	selection_map.move_to(to_pos, _offset)
	update_selection()


func resize_to(to_size :Vector2i):	
	if to_size.x > size.x:
		to_size.x = size.x
	elif to_size.x < 1:
		to_size.x = 1
		
	if to_size.y > size.y:
		to_size.y = size.y
	elif to_size.y < 1:
		to_size.y = 1
		
	selection_map.resize_to(to_size, get_pivot_offset(to_size))
	update_selection()


func get_rect_from_points(pts) -> Rect2i:
	return Rect2i(pts[0], pts[pts.size()-1] - pts[0]).abs()


func check_visible(sel_points) -> bool:
	visible = true if sel_points.size() > 1 else false
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


func parse_points(sel_points:PackedVector2Array):
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



# Rectangle

func selecting_rectangle(sel_points :Array):
	sel_points = parse_points(sel_points)
	if not check_visible(sel_points):
		return
	_current_draw = _draw_rectangle
	points = sel_points
	queue_redraw()


func selected_rectangle(sel_points :Array):
	sel_points = parse_points(sel_points)
	if not check_visible(sel_points):
		return
	var sel_rect := get_rect_from_points(sel_points)
	selection_map.select_rect(
		sel_rect, as_replace, as_subtract, as_intersect)
	update_selection()
	points.clear()


# Ellipse

func selecting_ellipse(sel_points :Array):
	sel_points = parse_points(sel_points)
	if not check_visible(sel_points):
		return
	_current_draw = _draw_ellipse
	points = sel_points
	queue_redraw()


func selected_ellipse(sel_points :Array):
	sel_points = parse_points(sel_points)
	if not check_visible(sel_points):
		return
	var sel_rect := get_rect_from_points(sel_points)
	selection_map.select_ellipse(
		sel_rect, as_replace, as_subtract, as_intersect)
	update_selection()
	points.clear()


# Polygon

func selecting_polygon(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_draw = _draw_polyline
	points = sel_points
	queue_redraw()


func selected_polygon(sel_points :Array):
	if not check_visible(sel_points):
		return
	selection_map.select_polygon(
		sel_points, as_replace, as_subtract, as_intersect)
	update_selection()
	points.clear()


# Lasso

func selecting_lasso(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_draw = _draw_polyline
	points = sel_points
	queue_redraw()


func selected_lasso(sel_points :Array):
	if not check_visible(sel_points):
		return
	selection_map.select_polygon(
		sel_points, as_replace, as_subtract, as_intersect)
	update_selection()
	points.clear()


# magic
func selected_magic(sel_points :Array):
	if not check_visible(sel_points):
		return
		
	selection_map.select_magic(
		sel_points, as_replace, as_subtract, as_intersect)
	update_selection()
	points.clear()


# Draw selecting lines

func _draw():
	if points.size() > 1:
		_current_draw.call()	
		# switch in `selection_` func.
		# try not use state, so many states in proejcts already.
		# also there is internal useage for this class only.


var _current_draw = _draw_nothing


var _draw_nothing = func():
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


var _draw_polyline = func():
	draw_polyline(points, Color.WHITE, 1 / zoom_ratio)
	

func _input(event):
	if event is InputEventKey:
		var delta := 1
		
		if Input.is_key_pressed(KEY_SHIFT):
			delta = 10
			
		if Input.is_action_pressed('ui_up'):
			if selected_rect.position.y < delta:
				delta = selected_rect.position.y
			selection_map.move_delta(-delta, VERTICAL)
			update_selection()
		
		elif Input.is_action_pressed('ui_right'):
			var right_remain := size.x - selected_rect.end.x
			if right_remain < delta:
				delta = right_remain
			selection_map.move_delta(delta, HORIZONTAL)
			update_selection()
		
		elif Input.is_action_pressed('ui_down'):
			var bottom_remain := size.y - selected_rect.end.y
			if bottom_remain < delta:
				delta = bottom_remain
			selection_map.move_delta(delta, VERTICAL)
			update_selection()
		
		elif Input.is_action_pressed('ui_left'):
			if selected_rect.position.x < delta:
				delta = selected_rect.position.x
			selection_map.move_delta(-delta, HORIZONTAL)
			update_selection()
	
	
