class_name CircleSelector extends BaseSelector


func select_move(pos :Vector2i):
	super.select_move(pos)
	if points.size() > 0:
		# only keep frist points for rectangle.
		points.resize(1)
	points.append(pos) # append last point for rectangle.
	
	selection.selecting(parse_regular_points(points), Selection.CIRCLE)


func select_end(_pos):
	is_selecting = false
	selection.selected(parse_regular_points(points), mode, Selection.CIRCLE)



