class_name LassoSelector extends BaseSelector


func select_move(pos :Vector2i):
	super.select_move(pos)
	points.append(pos)
	selection.selecting_lasso(points)


func select_end(_pos):
	is_selecting = false
	selection.selected_lasso(points, as_replace, as_subtract, as_intersect)
