extends Node2D


func _draw():
	var project = g.current_project
	var current_frame :int = project.current_frame
	var current_cels :Array = project.frames[current_frame].cels
	
	for i in range(project.layers.size()):
		if current_cels[i] is GroupCel:
			continue

		var is_visible = project.layers[i].is_visible_in_hierarchy()
		if is_visible and current_cels[i].opacity > 0:
			var modulate_color = Color(1, 1, 1, current_cels[i].opacity)
			draw_texture(current_cels[i].image_texture, Vector2.ZERO, modulate_color)
