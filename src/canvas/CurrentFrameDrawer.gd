extends Node2D


func _draw():
	var project = g.current_project
	if not project:
		return

	for i in project.layers.size():
		var layer = project.layers[i]
		var cel = project.current_frame.cels[i]
		if cel is GroupCel:
			continue
		if layer.is_visible_in_hierarchy() and layer.opacity > 0:
			var modulate_color := Color(1, 1, 1, layer.opacity)
			draw_texture(cel.image_texture, Vector2.ZERO, modulate_color)
