extends Sprite2D

class_name Selection



func _ready():
	visible = false
	material.set_shader_parameter("width", 10)
#	material.set_shader_parameter("width", 1.0 / zoom)
	material.set_shader_parameter("frequency", 100)




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
