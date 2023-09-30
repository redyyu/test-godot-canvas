class_name PolygonSelector extends BaseSelector


func select_move(pos :Vector2i):
	super.select_move(pos)
	points.append(pos) # append last point for rectangle.
	
	selection.selecting_polygon(parse_regular_points(points))


func select_end(_pos):
	is_selecting = false
	selection.selected_polygon(parse_regular_points(points),
							   as_replace, as_subtract, as_intersect)
