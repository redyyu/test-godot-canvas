class_name RectShaper extends BaseShaper


func shape_move(pos :Vector2i):
	super.shape_move(pos)
	if is_shaping:
		if points.size() > 0:
			# only keep frist points for rectangle.
			points.resize(1)
		points.append(pos) # append last point for rectangle.
		shaping_area.shaping_rectangle(points)
	elif is_moving:
		move_to(pos)


func shape_end(pos :Vector2i):
	if is_shaping:
		shaping_area.shaping_rectangle(points)
	super.shape_end(pos)

