class_name BaseDrawer extends RefCounted

var horizontal_mirror := false
var vertical_mirror := false
var color_op := ColorOp.new()

var is_drawing := false

var image := Image.new() :
	set(img):
		image = img
		size = Vector2i(image.get_width(), image.get_height())

var size := Vector2i.ONE :
	set(_size):
		size = _size
		draw_rect = Rect2i(Vector2i.ZERO, size)

var draw_rect := Rect2i(Vector2i.ZERO, Vector2i.ZERO)
var draw_start_position := Vector2i.ZERO
var draw_spacing_mode :bool :
	get: return stroke_spacing != Vector2i.ZERO

var stroke_dimensions :Vector2i :
	get: return Vector2i(stroke_width, stroke_width)
	# use stroke_max to get dimensions.
		
var stroke_spacing := Vector2i.ZERO  # the space between each draw strokes.
var stroke_color := Color.WHEAT

var stroke_width := 1 :
	set(val):
		# weight must less 1, and not greater than 600
		stroke_width = clampi(val, 1, 100)
		stroke_width_dynamics = stroke_width

var stroke_width_dynamics :int = stroke_width

var stroke_width_dynamics_minimal := 1

var alpha := 1.0 :
	set(val):
		alpha = clampf(val, 0.0, 1.0)
		color_op.strength = alpha
		
var stroke_alpha_dynamics_minimal := 0.0

var allow_dyn_stroke_alpha := false
var allow_dyn_stroke_width := false

var cursor_position := Vector2i.ZERO

var spacing_factor :Vector2i :
	get: return stroke_dimensions + stroke_spacing
	# spacing_factor is the distance the mouse needs to get snapped by in order
	# to keep a space `stroke_spacing` between two strokes 
	# of dimensions `stroke_dimensions`.

var last_position :Vector2i


class ColorOp:
	var strength := 1.0
	

func can_draw(pos :Vector2i):
	if image.is_empty():
		return false
	else:
		return draw_rect.has_point(pos) and _can_draw_hook.call(pos)


var _can_draw_hook = func(_pos :Vector2i):
	return true


func set_can_draw_hook(function:Variant):
	if function is Callable:
		_can_draw_hook = function
	else:
		_can_draw_hook = func(_pos :Vector2i):
			return true


func draw_start(pos: Vector2i):
	is_drawing = true
	last_position = pos
	draw_start_position = pos
	draw_pixel(pos)


func draw_move(pos: Vector2i):
	# This can happen if the user switches between tools with a shortcut
	# while using another tool
	if !is_drawing:
		draw_start(pos)
	draw_fill_gap(last_position, pos)
	last_position = pos


func draw_end(_pos: Vector2i):
	is_drawing = false
#	draw_pixel(pos)
	# no need draw in the end.


func cursor_move(pos: Vector2i):
	if draw_spacing_mode and is_drawing:
		cursor_position = get_spacing_position(pos)
	else:
		cursor_position = pos


func _get_spacing_offset(pos: Vector2i) -> Vector2i:
	# since we just started drawing, the "position" is our intended location
	# so the error (_spacing_offset) is measured by subtracting `space_factor`
	return pos - pos.snapped(spacing_factor)


func get_spacing_position(pos: Vector2i) -> Vector2i:
	var _spacing_offset = _get_spacing_offset(draw_start_position)
	# get spacing offset must by the position when draw start.
	# otherwise the spaceing offset will update every time.
	var snap_pos := Vector2(pos.snapped(spacing_factor) + _spacing_offset)

	# keeping snap_pos as is would have been fine 
	# but this adds extra accuracy as to
	# which snap point (from the list below) 
	# is closest to mouse and occupy THAT point
	var t_l := snap_pos + Vector2(-spacing_factor.x, -spacing_factor.y)
	var t_c := snap_pos + Vector2(0, -spacing_factor.y) 
	# t_c is for "top centre" and so on...
	
	var t_r := snap_pos + Vector2(spacing_factor.x, -spacing_factor.y)
	var m_l := snap_pos + Vector2(-spacing_factor.x, 0)
	var m_c := snap_pos
	var m_r := snap_pos + Vector2(spacing_factor.x, 0)
	var b_l := snap_pos + Vector2(-spacing_factor.x, spacing_factor.y)
	var b_c := snap_pos + Vector2(0, spacing_factor.y)
	var b_r := snap_pos + Vector2(spacing_factor.x, spacing_factor.y)
	var vec_arr: PackedVector2Array = [
		t_l, t_c, t_r, m_l, m_c, m_r, b_l, b_c, b_r
	]
	for vec in vec_arr:
		if vec.distance_to(pos) < snap_pos.distance_to(pos):
			snap_pos = vec

	return Vector2i(snap_pos)


func draw_pixel(_position: Vector2i):
	pass


# Bresenham's Algorithm, Thanks to 
# https://godotengine.org/qa/35276/tile-based-line-drawing-algorithm-efficiency
func draw_fill_gap(start: Vector2i, end: Vector2i):
	var dx := absi(end.x - start.x)
	var dy := -absi(end.y - start.y)
	var err := dx + dy
	var e2 := err << 1
	var sx := 1 if start.x < end.x else -1
	var sy := 1 if start.y < end.y else -1
	var x := start.x
	var y := start.y
	# This needs to be a dictionary to ensure duplicate coordinates are not being added
	var coords_to_draw := {}
	while !(x == end.x && y == end.y):
		e2 = err << 1
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
		
		var coord := Vector2(x, y)
		
		if draw_spacing_mode:
			coord = get_spacing_position(coord)
			
		coords_to_draw[coord] = 0

	for c in coords_to_draw.keys():
		draw_pixel(c)


func set_stroke_width_dynamics(value := 1.0):
	if value < 0:
		return
		
	value = clampf(value, 0.1, 1.0)

	if allow_dyn_stroke_width: 
		stroke_width_dynamics = roundi(
			lerpf(stroke_width_dynamics_minimal, stroke_width, value))
	else:
		# dynamics might changed, must switch back to default width.
		stroke_width_dynamics = stroke_width


func set_stroke_alpha_dynamics(value := 1.0):
	if value < 0:
		return
	
	if allow_dyn_stroke_alpha:
		color_op.strength = lerpf(stroke_alpha_dynamics_minimal, alpha, value)
	else:
		# dynamics might changed, must switch back to default alpha.
		color_op.strength = alpha
