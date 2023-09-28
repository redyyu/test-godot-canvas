extends Node2D

class_name SymmetryGuide

enum {
	NONE,
	HORIZONTAL_AXIS,
	VERTICAL_AXIS,
	CROSS_AXIS,
}

var state := NONE :
	set(val):
		state = val
		if state == NONE:
			hide()
		else:
			show()

var guide_color := Color.DARK_SALMON:
	set(val):
		guide_color = val
		h_symmetry_guide.default_color = guide_color
		v_symmetry_guide.default_color = guide_color
		
var h_symmetry_guide := Line2D.new()
var v_symmetry_guide := Line2D.new()


func _ready():
	h_symmetry_guide.width = 1
	h_symmetry_guide.default_color = guide_color
	h_symmetry_guide.modulate.a = 0.6
	v_symmetry_guide.width = 1
	v_symmetry_guide.default_color = guide_color
	v_symmetry_guide.modulate.a = 0.6
	
	add_child(h_symmetry_guide)
	add_child(v_symmetry_guide)


func set_guide(size :Vector2i):
	h_symmetry_guide.clear_points()
	v_symmetry_guide.clear_points()
		
	h_symmetry_guide.add_point(Vector2(0, 0))
	h_symmetry_guide.add_point(Vector2(size.x, 0))
	v_symmetry_guide.add_point(Vector2(0, 0))
	v_symmetry_guide.add_point(Vector2(0, size.y))


func move_guide(size :Vector2, canvas_size: Vector2,
				origin :Vector2, zoom :Vector2):
	if not visible:
		return

	match state:
		SymmetryGuide.HORIZONTAL_AXIS:
			_set_horizontal_symmetry_guide(size, canvas_size, origin, zoom)
		SymmetryGuide.VERTICAL_AXIS:
			_set_vertical_symmetry_guide(size, canvas_size, origin, zoom)
		SymmetryGuide.CROSS_AXIS:
			_set_horizontal_symmetry_guide(size, canvas_size, origin, zoom)
			_set_vertical_symmetry_guide(size, canvas_size, origin, zoom)


func _set_horizontal_symmetry_guide(size :Vector2, canvas_size: Vector2, 
									origin :Vector2, zoom :Vector2):
	var _y = origin.y + canvas_size.y * 0.5 * zoom.y
	h_symmetry_guide.set_guide(Vector2(-size.x, _y), Vector2(size.x, _y))


func _set_vertical_symmetry_guide(size :Vector2, canvas_size: Vector2, 
								  origin :Vector2, zoom :Vector2):
	var _x = origin.x + canvas_size.x * 0.5 * zoom.x
	v_symmetry_guide.set_guide(Vector2(_x, -size.y), Vector2(_x, size.y))
