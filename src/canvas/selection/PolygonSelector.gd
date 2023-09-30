class_name PolygonSelector extends BaseSelector


func select_move(pos :Vector2i):
	super.select_move(pos)
	points.append(pos)
	selection.selecting_polygon(points)


func select_end(_pos):
	is_selecting = false
	selection.selected_polygon(points, as_replace, as_subtract, as_intersect)
