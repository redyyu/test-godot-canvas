class_name RectSelector extends BaseSelector


func select_move(pos :Vector2i):
	super.select_move(pos)
	if points.size() > 0:
		# only keep frist points for rectangle.
		points.resize(1)
	points.append(pos) # append last point for rectangle.
	
	selection.selecting(parse_points(points), Selection.SelectType.RECTANGLE)


func select_end(_pos):
	is_selecting = false
	selection.selected_rect(parse_points(points), mode)


func parse_points(sel_points):
	var pts := []
	var start := points[0]
	var end := points[1]
	var sel_size := (start - end).abs()
	
	if opt_as_square:
		# Make rect 1:1 while centering it on the mouse
		var square_size := maxi(sel_size.x, sel_size.y)
		sel_size = Vector2i(square_size, square_size)
		end = start - sel_size if start > end else start + sel_size

	if opt_from_center:
		if start < end:
			start -= sel_size
			end += 2 * sel_size
		else:
			var _start = end - 2 * sel_size
			end = start + sel_size
			start = _start

	pts.append(start)
	pts.append(end)
	return pts
