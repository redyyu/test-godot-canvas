class_name EllipseSelector extends BaseSelector


func select_move(pos :Vector2i):
	super.select_move(pos)
	if points.size() > 0:
		# only keep frist points for rectangle.
		points.resize(1)
	points.append(pos) # append last point for rectangle.
	selection.selecting_ellipse(parse_rectangle_points(points))


func select_end(_pos):
	is_selecting = false
	selection.selected_ellipse(parse_rectangle_points(points),
							   as_replace, as_subtract, as_intersect)



