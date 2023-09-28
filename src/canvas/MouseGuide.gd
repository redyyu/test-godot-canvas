extends Node2D

var guide_color := Color.MINT_CREAM:
	set(val):
		guide_color = val
		h_mouse_guide.default_color = guide_color
		v_mouse_guide.default_color = guide_color

var guide_alpha := 0.33:
	set(val):
		guide_alpha = clampf(val, 0.1, 1.0)
		h_mouse_guide.modulate.a = guide_alpha
		v_mouse_guide.modulate.a = guide_alpha
		

var h_mouse_guide := Line2D.new()
var v_mouse_guide := Line2D.new()


func _ready():
	h_mouse_guide.width = 1
	v_mouse_guide.width = 1
	h_mouse_guide.default_color = guide_color
	v_mouse_guide.default_color = guide_color
	h_mouse_guide.modulate.a = guide_alpha
	v_mouse_guide.modulate.a = guide_alpha
	add_child(h_mouse_guide)
	add_child(v_mouse_guide)


func set_guide(size :Vector2i):
	h_mouse_guide.clear_points()
	v_mouse_guide.clear_points()
	
	h_mouse_guide.add_point(Vector2(0, 0))
	h_mouse_guide.add_point(Vector2(size.x, 0))
	v_mouse_guide.add_point(Vector2(0, 0))
	v_mouse_guide.add_point(Vector2(0, size.y))


func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseMotion:
		var mouse_pos = get_local_mouse_position()
		h_mouse_guide.position.y = mouse_pos.y
		v_mouse_guide.position.x = mouse_pos.x
