extends Line2D

class_name Guide

signal released(guide)
signal pressed(guide)

const DEFAULT_WIDTH := 2
const LINE_COLOR := Color.REBECCA_PURPLE

var orientation := HORIZONTAL
var locked := false
var is_pressed := false
var is_new := false


func _ready():
#	default_color = LINE_COLOR.lerp(Color(.2, .2, .65), .6)
	default_color = LINE_COLOR
	modulate.a = 0.6
	width = DEFAULT_WIDTH


func _input(event: InputEvent):
	if is_new:
		if (event is InputEventMouseButton and 
			event.button_index == MOUSE_BUTTON_LEFT):

			is_pressed = event.pressed
			if not is_pressed:
				released.emit(self)
				is_new = false
				
		if event is InputEventMouseMotion and is_pressed:
			match orientation:
				HORIZONTAL:
					position.y = get_global_mouse_position().y
				VERTICAL: 
					position.x = get_global_mouse_position().x
	else:
		if (event is InputEventMouseButton and event.pressed and 
			event.button_index == MOUSE_BUTTON_LEFT):
			if (orientation == HORIZONTAL and 
				abs(position.y - get_global_mouse_position().y) < 3 ):
				pressed.emit(self)
				is_pressed = true
			elif (orientation == VERTICAL and
				  abs(position.x - get_global_mouse_position().x) < 3):
				pressed.emit(self)
				is_pressed = true
				
		elif (event is InputEventMouseButton and not event.pressed):
			is_pressed = false
			released.emit(self)
				
		elif event is InputEventMouseMotion and is_pressed:
			match orientation:
				HORIZONTAL:
					position.y = get_global_mouse_position().y
				VERTICAL: 
					position.x = get_global_mouse_position().x


#func _draw() -> void:
#	if visible:
#		var font = get_theme_default_font()
#		var text = "%spx" % str(position.y if Types.HORIZONTAL else position.x) 
#		var font_height = font.get_height()
#
#		draw_string(font, Vector2(font_height, font_height), text,
#					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, default_color)


func set_guide(orient :Orientation, size :Vector2):
	is_new = true
	is_pressed = true
	clear_points()
	orientation = orient
	match orientation:
		HORIZONTAL:
			add_point(Vector2(-size.x, 0))
			add_point(Vector2(size.x, 0))
#			position.y = get_global_mouse_position().y
#			mouse_default_cursor_shape = Control.CURSOR_VSPLIT
		VERTICAL:
			add_point(Vector2(0, -size.y))
			add_point(Vector2(0, size.y))
#			position.x = get_global_mouse_position().x
