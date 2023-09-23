extends Button

class_name Ruler

signal guide_created(orientation)

const RULER_WIDTH := 16

var major_subdivision := 2
var minor_subdivision := 4

var first := Vector2.ZERO
var last := Vector2.ZERO

var zoom := Vector2.ZERO
var canvas_size := Vector2i.ZERO
var viewport_size := Vector2i.ZERO
var camera_offset := Vector2.ZERO

var btn_pressed := false
var mouse_position := Vector2.ZERO
var create_guide_gate := false

enum {
	HORIZONTAL,
	VERTICAL
}

var orientation := HORIZONTAL


func _ready():
	focus_mode = Control.FOCUS_NONE
	
	if name.begins_with('H'):
		orientation = HORIZONTAL
	elif name.begins_with('V'):
		orientation = VERTICAL
		
	if orientation == HORIZONTAL:
		mouse_default_cursor_shape = Control.CURSOR_VSPLIT
	else:
		mouse_default_cursor_shape = Control.CURSOR_HSPLIT


func set_ruler(_size :Vector2i, _canvas_size :Vector2i,
			   _offset :Vector2, _zoom :Vector2):
	viewport_size = _size
	canvas_size = _canvas_size
	camera_offset = _offset
	zoom = _zoom
	
	if orientation == HORIZONTAL:
		size.x = viewport_size.x
		size.y = RULER_WIDTH
	else:
		size.x = RULER_WIDTH
		size.y = viewport_size.y
		
	queue_redraw()


# Code taken and modified from Godot's source code
func _draw():
	if orientation == HORIZONTAL:
		draw_h()
	else:
		draw_v()
		

func draw_h():
	var font: Font = get_theme_default_font()
	var transform := Transform2D()
	var ruler_transform := Transform2D()
	var major_subdivide := Transform2D()
	var minor_subdivide := Transform2D()
	
	transform.x = Vector2(zoom.x, zoom.x)
	transform.origin = (
		viewport_size * 0.5 + camera_offset * -zoom.x
	)
	
	var basic_rule := 100.0
	var i := 0
	while basic_rule * zoom.x > 100:
		basic_rule /= 5.0 if i % 2 else 2.0
		i += 1
		
	i = 0
	while basic_rule * zoom.x < 100:
		basic_rule *= 2.0 if i % 2 else 5.0
		i += 1
	
	ruler_transform = ruler_transform.scaled(Vector2(basic_rule, basic_rule))
	
	major_subdivide = major_subdivide.scaled(
		Vector2(1.0 / major_subdivision, 1.0 / major_subdivision)
	)
	minor_subdivide = minor_subdivide.scaled(
		Vector2(1.0 / minor_subdivision, 1.0 / minor_subdivision)
	)

	first = (
		(transform * ruler_transform * major_subdivide * minor_subdivide).affine_inverse()
		* (Vector2.ZERO)
	)
	last = (
		(transform * ruler_transform * major_subdivide * minor_subdivide).affine_inverse()
		* get_parent().size
	)
	
	for j in range(ceili(first.x), ceili(last.x)):
		var pos: Vector2 = (
			(transform * ruler_transform * major_subdivide * minor_subdivide) 
			* (Vector2(j, 0))
		)
		if j % (major_subdivision * minor_subdivision) == 0:
			draw_line(
				Vector2(pos.x, 0),
				Vector2(pos.x, RULER_WIDTH),
				Color.WHITE
			)
			var val := ((ruler_transform * major_subdivide * minor_subdivide) 
						* Vector2(j, 0)).x
			draw_string(
				font,
				Vector2(pos.x + 2, font.get_height() - 14),
				str(snappedf(val, 0.1)), 
				HORIZONTAL_ALIGNMENT_LEFT, -1, 9
			)
		else:
			if j % minor_subdivision == 0:
				draw_line(
					Vector2(pos.x, RULER_WIDTH * 0.33),
					Vector2(pos.x, RULER_WIDTH),
					Color.WHITE
				)
			else:
				draw_line(
					Vector2(pos.x, RULER_WIDTH * 0.66),
					Vector2(pos.x, RULER_WIDTH),
					Color.WHITE
				)


func draw_v():
	var font: Font = get_theme_default_font()
	var transform := Transform2D()
	var ruler_transform := Transform2D()
	var major_subdivide := Transform2D()
	var minor_subdivide := Transform2D()
	
	transform.y = Vector2(zoom.y, zoom.y)
	transform.origin = (
		viewport_size * 0.5 + camera_offset * -zoom.y
	)
	
	var basic_rule := 100.0
	var i := 0
	while basic_rule * zoom.y > 100:
		basic_rule /= 5.0 if i % 2 else 2.0
		i += 1
		
	i = 0
	while basic_rule * zoom.y < 100:
		basic_rule *= 2.0 if i % 2 else 5.0
		i += 1
	
	ruler_transform = ruler_transform.scaled(Vector2(basic_rule, basic_rule))
	
	major_subdivide = major_subdivide.scaled(
		Vector2(1.0 / major_subdivision, 1.0 / major_subdivision)
	)
	minor_subdivide = minor_subdivide.scaled(
		Vector2(1.0 / minor_subdivision, 1.0 / minor_subdivision)
	)

	first = (
		(transform * ruler_transform * major_subdivide * minor_subdivide).affine_inverse()
		* (Vector2.ZERO)
	)
	last = (
		(transform * ruler_transform * major_subdivide * minor_subdivide).affine_inverse()
		* get_parent().size
	)
	
	for j in range(ceili(first.y), ceili(last.y)):
		var pos: Vector2 = (
			(transform * ruler_transform * major_subdivide * minor_subdivide) 
			* (Vector2(0, j))
		)
		if j % (major_subdivision * minor_subdivision) == 0:
			draw_line(
				Vector2(0, pos.y),
				Vector2(RULER_WIDTH, pos.y),
				Color.WHITE
			)
			var val := ((ruler_transform * major_subdivide * minor_subdivide) 
						* Vector2(0, j)).y
			draw_string(
				font,
				Vector2(0, pos.y + 12),
				str(snappedf(val, 0.1)), 
				HORIZONTAL_ALIGNMENT_LEFT, -1, 9
			)
		else:
			if j % minor_subdivision == 0:
				draw_line(
					Vector2(RULER_WIDTH * 0.33, pos.y),
					Vector2(RULER_WIDTH, pos.y),
					Color.WHITE
				)
			else:
				draw_line(
					Vector2(RULER_WIDTH * 0.66, pos.y),
					Vector2(RULER_WIDTH, pos.y),
					Color.WHITE
				)


func _input(event):
	
	if event is InputEventMouse:
		var mouse_position = get_local_mouse_position()
		var rect = Rect2i(Vector2i.ZERO, size)
		
		if (event is InputEventMouseButton and 
			event.button_index == MOUSE_BUTTON_LEFT):
			if rect.has_point(mouse_position):
				btn_pressed = event.pressed
			else:
				btn_pressed = false
			
		elif event is InputEventMouseMotion:
			if rect.has_point(mouse_position) and not btn_pressed:
				create_guide_gate = true
				
			if not rect.has_point(mouse_position) and btn_pressed:
				if create_guide_gate:
					create_guide_gate = false
					guide_created.emit(orientation)

