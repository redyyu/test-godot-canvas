class_name RectSelector extends PixelSelector

func select_move(pos :Vector2i):
	super.select_move(pos)
	
	if is_selecting:
		if points.size() > 1:
			# only keep frist points for rectangle.
			points.resize(1)
		points.append(pos) # append last point for rectangle.
		selection.selecting_rectangle(points)

	elif is_moving:
		selection.drag_to(pos, drag_offset)


func select_end(pos :Vector2i):
	if is_selecting:
		selection.selected_rectangle(points)
	super.select_end(pos)
