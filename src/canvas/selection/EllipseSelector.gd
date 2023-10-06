class_name EllipseSelector extends PixelSelector

func select_move(pos :Vector2i):
	super.select_move(pos)

	if is_selecting:
		if points.size() > 0:
			# only keep frist points for rectangle.
			points.resize(1)
		points.append(pos) # append last point for rectangle.
		selection.selecting_ellipse(points)

	elif is_moving:
		move_to(pos)


func select_end(pos):
	if is_selecting:
		selection.selected_ellipse(points)
	super.select_end(pos)

