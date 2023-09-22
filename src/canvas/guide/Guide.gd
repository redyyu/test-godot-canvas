extends Line2D

class_name Guide

enum Types {
	HORIZONTAL,
	VERTICAL
}

const DEFAULT_WIDTH :int = 2
const LINE_COLOR :Color = Color.PURPLE

var type :Types = Types.HORIZONTAL

var locked :bool = false
var has_focus :bool = false
var mouse_start_pos :Vector2 = Vector2.ZERO
var font :Font 


func _ready():
	default_color = LINE_COLOR
	modulate.a = 0.5
	width = DEFAULT_WIDTH


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		has_focus = event.pressed
	if (event is InputEventMouseButton and has_focus and
		event.button_index == MOUSE_BUTTON_LEFT):
		mouse_start_pos = get_global_mouse_position()
	elif event is InputEventMouseMotion and has_focus:
		var delta :float = 0
		match type:
			Types.HORIZONTAL:
				delta = get_global_mouse_position().y - mouse_start_pos.y
				position.y += delta
				queue_redraw()
			Types.VERTICAL: 
				delta = get_global_mouse_position().x - mouse_start_pos.x
				position.x += delta
				queue_redraw()


func _draw() -> void:
	if not has_focus or not font:
		return
	var text = "%spx" % str(position.y if Types.HORIZONTAL else position.x) 
	var font_height = font.get_height()

	draw_string(font, Vector2(font_height, font_height), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, default_color)


func set_guide(y_or_x, length :int):
	match type:
		Types.HORIZONTAL:
			position.y = y_or_x
		Types.VERTICAL:
			position.x = y_or_x

	points.append_array([Vector2i.ZERO, Vector2i(0, length)]) 


func set_color(color :Color):
	default_color = color


func set_font(theme_font :Font):
	font = theme_font
