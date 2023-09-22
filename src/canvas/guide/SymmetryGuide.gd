extends Line2D

class_name SymmetryGuide

#var _texture := preload("res://assets/icon.svg")


func _ready():
#	texture = _texture
#	texture_repeat = TEXTURE_REPEAT_ENABLED
#	texture_mode = LINE_TEXTURE_TILE 
	width = 1
	
	default_color = Color.PALE_VIOLET_RED.lerp(Color(.2, .2, .65), .6)
	hide()


func set_guide(start_point :Vector2, end_point :Vector2):
	clear_points()
	add_point(start_point)
	add_point(end_point)
