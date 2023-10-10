class_name EllipseShaper extends BaseShaper


func shaping(pos :Vector2i):
	super.shaping(pos)
	if is_shaping:
		if points.size() > 1:
			# only keep frist points for rectangle.
			points.resize(1)
		points.append(pos) # append last point for rectangle.
		silhouette.shaping_ellipse(points)


func shaping_stop():
	silhouette.shaped_ellipse()
	super.shaping_stop()
