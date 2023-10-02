class_name SymmetryGuide extends Node2D

enum {
	NONE,
	HORIZONTAL_AXIS,
	VERTICAL_AXIS,
	CROSS_AXIS,
}

var state := NONE
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
	h_symmetry_guide.visible = false
	v_symmetry_guide.width = 1
	v_symmetry_guide.default_color = guide_color
	v_symmetry_guide.modulate.a = 0.6
	v_symmetry_guide.visible = false
	
	add_child(h_symmetry_guide)
	add_child(v_symmetry_guide)


func set_guide(size :Vector2i):
	h_symmetry_guide.clear_points()
	h_symmetry_guide.add_point(Vector2(0, 0))
	h_symmetry_guide.add_point(Vector2(size.x, 0))
	h_symmetry_guide.hide()
	
	v_symmetry_guide.clear_points()
	v_symmetry_guide.add_point(Vector2(0, 0))
	v_symmetry_guide.add_point(Vector2(0, size.y))
	v_symmetry_guide.hide()
	
	show()
	
	match state:
		HORIZONTAL_AXIS:
			h_symmetry_guide.show()
		VERTICAL_AXIS:
			v_symmetry_guide.show()
		CROSS_AXIS:
			h_symmetry_guide.show()
			v_symmetry_guide.show()
		_:
			hide()


func resize(size :Vector2):
	h_symmetry_guide.points[1].x = size.x
	v_symmetry_guide.points[1].y = size.y


func move(canvas_size :Vector2, origin :Vector2, zoom :Vector2):
	if not visible:
		return
	var _y = origin.y + canvas_size.y * 0.5 * zoom.y
	var _x = origin.x + canvas_size.x * 0.5 * zoom.x
	match state:
		SymmetryGuide.HORIZONTAL_AXIS:
			h_symmetry_guide.position.y = _y
		SymmetryGuide.VERTICAL_AXIS:
			v_symmetry_guide.position.x = _x
		SymmetryGuide.CROSS_AXIS:
			h_symmetry_guide.position.y = _y
			v_symmetry_guide.position.x = _x
 
