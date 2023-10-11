class_name EllipseShaper extends BaseShaper


func shape_move(pos :Vector2i):
	super.shape_move(pos)
	if is_shaping:
		if points.size() > 1:
			# only keep frist points for rectangle.
			points.resize(1)
		points.append(pos) # append last point for rectangle.
		silhouette.shaping_ellipse(points)
	elif is_moving:
		silhouette.move_to(pos)


func apply():
	if points.size() > 0:
		silhouette.shaped_ellipse()
	super.apply()
