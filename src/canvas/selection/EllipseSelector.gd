class_name EllipseSelector extends PixelSelector

func select_move(pos :Vector2i):
	super.select_move(pos)

	if is_selecting:
		if points.size() > 1:
			# only keep frist points for rectangle.
			points.resize(1)
		points.append(pos) # append last point for rectangle.
		selection.selecting_ellipse(points)

	elif is_moving:
		selection.move_to(pos)


func select_end(pos :Vector2i):
	if is_selecting:
		selection.selected_ellipse(points)
	super.select_end(pos)

