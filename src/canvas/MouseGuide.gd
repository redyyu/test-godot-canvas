extends Node2D

var guide_color := Color.DARK_SALMON:
	set(val):
		guide_color = val
		h_guide.default_color = guide_color
		v_guide.default_color = guide_color
		
var h_guide := Line2D.new()
var v_guide := Line2D.new()


func _ready() -> void:
	h_guide.width = 1
	v_guide.width = 1
	h_guide.default_color = guide_color
	v_guide.default_color = guide_color
	add_child(h_guide)
	add_child(v_guide)


func set_mouse_guide(size :Vector2i, color = null):
	h_guide.clear_points()
	v_guide.clear_points()
	
	if color is Color:
		guide_color = color
	
	h_guide.add_point(Vector2(0, 0))
	h_guide.add_point(Vector2(size.x, 0))
	v_guide.add_point(Vector2(0, 0))
	v_guide.add_point(Vector2(0, size.y))


func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseMotion:
		var mouse_pos = get_local_mouse_position()
		h_guide.position.y = mouse_pos.y
		v_guide.position.x = mouse_pos.x
