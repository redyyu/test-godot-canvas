class_name Selection extends Sprite2D

var zoom_percent := 1.0
var max_length :int :
	get:
		if texture: 
			return maxi(texture.get_width(), texture.get_height())
		else:
			return 0


class Gizmo:
	
	extends Control
	
	const SIZE := Vector2(6, 6) 
	var rect := Rect2(-SIZE/2, SIZE)
	var direction := Vector2i.ZERO

	func _init(_direction := Vector2i.ZERO):
		direction = _direction

		if direction == Vector2i.ZERO:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		elif direction == Vector2i(-1, -1) or direction == Vector2i(1, 1):
			# Top left or bottom right:
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		elif direction == Vector2i(1, -1) or direction == Vector2i(-1, 1):
			# Top right or bottom left
			mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		elif direction == Vector2i(0, -1) or direction == Vector2i(0, 1):
			# Center top or center bottom
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
		elif direction == Vector2i(-1, 0) or direction == Vector2i(1, 0):
			# Center left or center right
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		else:
			mouse_default_cursor_shape = Control.CURSOR_MOVE


func _ready():
#	visible = false
	
	material.set_shader_parameter("width", 1.0 / zoom_percent)
	material.set_shader_parameter("frequency", zoom_percent * 10 * max_length / 64)


func _draw():
	draw_rect(Rect2i(Vector2i.ZERO, Vector2i(50, 50))


func select(size):
	pass

#func _update_on_zoom() -> void:
#	var size := maxi(
#		Global.current_project.selection_map.get_size().x,
#		Global.current_project.selection_map.get_size().y
#	)
#	marching_ants_outline.material.set_shader_parameter("width", 1.0 / zoom)
#	marching_ants_outline.material.set_shader_parameter("frequency", zoom * 10 * size / 64)
#	for gizmo in gizmos:
#		if gizmo.rect.size == Vector2.ZERO:
#			return
#	_update_gizmos()


#func move_borders(move: Vector2i) -> void:
#	if move == Vector2i.ZERO:
#		return
#	marching_ants_outline.offset += Vector2(move)
#	big_bounding_rectangle.position += move
#	queue_redraw()
