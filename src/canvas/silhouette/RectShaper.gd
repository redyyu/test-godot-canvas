class_name RectShaper extends BaseShaper


func shaping(pos :Vector2i):
	super.shaping(pos)
	if is_shaping:
		if points.size() > 1:
			# only keep frist points for rectangle.
			points.resize(1)
		points.append(pos) # append last point for rectangle.
		silhouette.shaping_rectangle(points)
	elif is_moving:
		silhouette.move_to(pos)
