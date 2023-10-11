class_name LassoSelector extends PixelSelector


func select_move(pos :Vector2i):
	super.select_move(pos)
	if is_selecting:
		points.append(pos)
		selection.selecting_lasso(points)

	elif is_moving:
		selection.drag_to(pos, drag_offset)


func select_end(pos :Vector2i):
	if is_selecting:
		selection.selected_lasso(points)
	super.select_end(pos)
