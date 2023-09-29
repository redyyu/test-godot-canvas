class_name RectSelector extends BaseSelector


func select_move(pos :Vector2i):
	super.select_move(pos)
	if points.size() > 0:
		# only keep frist points for rectangle.
		points.resize(1)
	points.append(pos) # append last point for rectangle.
	selection.selecting(points, Selection.SelectType.RECTANGLE)


func select_end(_pos):
	is_selecting = false
	selection.selected(points, Selection.SelectType.RECTANGLE)
