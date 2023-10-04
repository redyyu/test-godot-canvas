class_name LassoSelector extends PixelSelector


func select_move(pos :Vector2i):
	super.select_move(pos)
	if is_selecting:
		points.append(pos)
		selection.selecting_lasso(points)

	elif is_moving:
		move_to(pos)


func select_end(pos):
	if is_selecting:
		selection.selected_lasso(points, as_replace, as_subtract, as_intersect)
	super.select_end(pos)
