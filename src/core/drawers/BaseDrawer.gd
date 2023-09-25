extends RefCounted

class_name BaseDrawer


var need_pressure :bool :
	get: return [
		use_dynamics_stroke,
		use_dynamics_alpha
	].any(func(val): return val == Dynamics.PRESSURE)
	

var need_velocity :bool :
	get: return [
		use_dynamics_stroke,
		use_dynamics_alpha
	].any(func(val): return val == Dynamics.VELOCITY)

var horizontal_mirror := false
var vertical_mirror := false
var color_op := ColorOp.new()

var is_drawing := false
var size := Vector2i.ONE :
	set(_size):
		size = _size
		draw_rect = Rect2i(Vector2i.ZERO, size)

var draw_rect := Rect2i(Vector2i.ZERO, Vector2i.ONE)
var draw_start_position := Vector2i.ZERO
var draw_spacing_mode :bool :
	get: return stroke_spacing != Vector2i.ZERO

var stroke_dimensions :Vector2i :
	get: return Vector2i(stroke_weight, stroke_weight)
	# use stroke_max to get dimensions.
		
var stroke_spacing := Vector2i.ZERO  # the space between each draw strokes.
var stroke_color := Color.WHEAT

var stroke_weight := 1 :
	set(val):
		# weight must less 1, and not greater than 600
		stroke_weight = clampi(val, 1, 600)

var stroke_dynamics_minimal := 1
		
var alpha := 1.0 :
	set(val):
		alpha = clampf(val, 0.0, 1.0)
		
var alpha_dynamics_minimal := 0.0

var use_dynamics_alpha := Dynamics.NONE
var use_dynamics_stroke := Dynamics.NONE
	
var pen_pressure := 1.0
var pen_velocity := 1.0

# High frequency val, try not to use setter / getter with operation.
var stroke_weight_dynamics :int = stroke_weight

var cursor_position := Vector2i.ZERO

var spacing_factor :Vector2i :
	get: return stroke_dimensions + stroke_spacing
	# spacing_factor is the distance the mouse needs to get snapped by in order
	# to keep a space `stroke_spacing` between two strokes 
	# of dimensions `stroke_dimensions`.
	
class ColorOp:
	var strength := 1.0


func can_draw(pos :Vector2i):
	return draw_rect.has_point(pos)
	

func draw_start(pos: Vector2i):
	is_drawing = true
	draw_start_position = pos


func draw_move(pos: Vector2i):
	# This can happen if the user switches between tools with a shortcut
	# while using another tool
	if !is_drawing:
		draw_start(pos)


func draw_end(_pos: Vector2i):
	is_drawing = false


func cursor_move(pos: Vector2i):
	if draw_spacing_mode and is_drawing:
		cursor_position = get_spacing_position(pos)
	else:
		cursor_position = pos


func get_spacing_offset(pos: Vector2i) -> Vector2i:
	# since we just started drawing, the "position" is our intended location
	# so the error (_spacing_offset) is measured by subtracting `space_factor`
	return pos - pos.snapped(spacing_factor)


func get_spacing_position(pos: Vector2i) -> Vector2i:
	var _spacing_offset = get_spacing_offset(draw_start_position)
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

	
func set_stroke_dynamics(pressure:float, velocity:float):
	pen_pressure = clampf(pressure, 0.1, 1.0)
	pen_velocity = clampf(velocity, 0.1, 1.0)

	match use_dynamics_stroke: 
		Dynamics.PRESSURE:
			stroke_weight_dynamics = roundi(
				lerpf(stroke_dynamics_minimal, stroke_weight, pen_pressure))
				
		Dynamics.VELOCITY:
			stroke_weight_dynamics = roundi(
				lerpf(stroke_dynamics_minimal, stroke_weight, pen_velocity))
		_:
			stroke_weight_dynamics = stroke_weight
	
	match use_dynamics_alpha:
		Dynamics.PRESSURE:
			color_op.strength = lerpf(alpha_dynamics_minimal, 
									  alpha, pen_pressure)
		Dynamics.VELOCITY:
			color_op.strength = lerpf(alpha_dynamics_minimal, 
									  alpha, pen_velocity)
		_:
			color_op.strength = alpha
