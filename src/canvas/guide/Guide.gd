extends Line2D

class_name Guide

signal released(guide)
signal pressed(guide)
signal hovered(guide)
signal leaved(guide)

const DEFAULT_WIDTH := 2
const LINE_COLOR := Color.REBECCA_PURPLE

var relative_position := Vector2.ZERO 
# it is calculated position to parent scene when zoom is 1.0
# use to keep the right position when place guide while is zoomed.

var orientation := HORIZONTAL
var locked := false
var is_pressed := false
var is_hovered := false


func _ready():
#	default_color = LINE_COLOR.lerp(Color(.2, .2, .65), .6)
	default_color = LINE_COLOR
	modulate.a = 0.6
	width = DEFAULT_WIDTH


func _input(event: InputEvent):
	if locked:
		return
		
	# grab a guide
	if (event is InputEventMouseButton and event.pressed and 
		event.button_index == MOUSE_BUTTON_LEFT):
		if orientation == HORIZONTAL and is_hovered:
			if not is_pressed:
				is_pressed = true
				pressed.emit(self)
		elif orientation == VERTICAL and is_hovered:
			if not is_pressed:
				is_pressed = true
				pressed.emit(self)
	
	# release a guide
	elif (event is InputEventMouseButton and not event.pressed):
		if is_pressed:
			is_pressed = false
			released.emit(self)
	
	# drag a guide		
	elif event is InputEventMouseMotion and is_pressed:
		match orientation:
			HORIZONTAL:
				position.y = get_global_mouse_position().y
			VERTICAL: 
				position.x = get_global_mouse_position().x
	
	# mouse over 
	elif event is InputEventMouseMotion:
		if orientation == HORIZONTAL:
			if abs(position.y - get_global_mouse_position().y) < 3:
				# check mouse is closet to guide.
				if not is_hovered:
					is_hovered = true
					hovered.emit(self)
			else:
				if is_hovered:
					is_hovered = false
					leaved.emit(self)
			
		elif orientation == VERTICAL:
			if abs(position.x - get_global_mouse_position().x) < 3:
				# check mouse is closet to guide.
				if not is_hovered:
					is_hovered = true
					hovered.emit(self)
			else:
				if is_hovered:
					is_hovered = false
					leaved.emit(self)


func set_guide(orient :Orientation, size :Vector2):
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
