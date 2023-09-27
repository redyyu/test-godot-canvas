extends Line2D

class_name SymmetryGuide

enum {
	NONE,
	HORIZONTAL_AXIS,
	VERTICAL_AXIS,
	CROSS_AXIS,
}


func _ready():
	width = 1
	default_color = Color.DARK_SALMON
	modulate.a = 0.6
	visible = false


func set_guide(start_point :Vector2, end_point :Vector2):
	clear_points()
	add_point(start_point)
	add_point(end_point)
