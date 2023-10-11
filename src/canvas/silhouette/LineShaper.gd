class_name LineShaper extends BaseShaper


func shape_move(pos :Vector2i):
	super.shape_move(pos)
	if is_shaping:
		if points.size() > 1:
			# only keep frist points for rectangle.
			points.resize(1)
		points.append(pos) # append last point for rectangle.
		silhouette.shaping_line(points)
	elif is_dragging:
		silhouette.drag_to(pos, drag_offset)


func apply():
	if points.size() > 0:
		silhouette.shaped_line()
	super.apply()
