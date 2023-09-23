extends ColorRect


func _ready():
	resized.connect(_on_resized)


func update_rect(canvas_size :Vector2i):
	# Set the size to be the same as the project size.
	set_bounds(canvas_size)
	
#	fit_rect(g.current_project.tiles.get_bounding_rect())
#	material.set_shader_parameter("size", g.checker_size)
#	material.set_shader_parameter("color1", g.checker_color_1)
#	material.set_shader_parameter("color2", g.checker_color_2)
#	material.set_shader_parameter("follow_movement", g.checker_follow_movement)
#	material.set_shader_parameter("follow_scale", g.checker_follow_scale)


func update_offset(offset: Vector2, canvas_scale: Vector2) -> void:
	material.set_shader_parameter("offset", offset)
	material.set_shader_parameter("scale", canvas_scale)


func set_bounds(bounds: Vector2) -> void:
	offset_right = bounds.x
	offset_bottom = bounds.y
#
#
func fit_rect(rect: Rect2) -> void:
	offset_left = rect.position.x
	offset_right = rect.position.x + rect.size.x
	offset_top = rect.position.y
	offset_bottom = rect.position.y + rect.size.y


func _on_resized():
	material.set_shader_parameter("rect_size", size)
