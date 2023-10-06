class_name PolygonSelector extends PixelSelector


func select_move(pos :Vector2i):
	super.select_move(pos)
	if is_selecting:
		points.append(pos)
		selection.selecting_polygon(points)

	elif is_moving:
		move_to(pos)


func select_end(pos):
	if is_selecting:
		selection.selected_polygon(points)
			
	super.select_end(pos)
