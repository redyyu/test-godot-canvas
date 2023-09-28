extends Node2D

class_name Grid

enum {
	NONE,
	ALL,
	CARTESIAN,
	ISOMETRIC,
}
var state := NONE :
	set(val):
		state = val
		queue_redraw()

var isometric_grid_size := Vector2i(96, 48)
var grid_size := Vector2i(48, 48)
var grid_color := Color.DEEP_SKY_BLUE:
	set(val):
		grid_color = val
		isometric_grid_color = Color(val)
		isometric_grid_color.a *= 0.66
var isometric_grid_color := Color(0, 0.74902, 0.66)
var pixel_grid_color := Color.LIGHT_BLUE

var show_pixel_grid_at_zoom := 16

var zoom_at := 1.0 :
	set(val):
		zoom_at = val
		queue_redraw()


var canvas_size := Vector2i.ZERO :
	set(val):
		canvas_size = val
		rect = Rect2i(Vector2.ZERO, canvas_size)
		queue_redraw()
		
var rect := Rect2i(Vector2.ZERO, canvas_size)


func _draw():
	if not rect.has_area() or state == NONE:
		return
	
	match state:
		ALL:
			draw_cartesian_grid()
			draw_isometric_grid()
		CARTESIAN:
			draw_cartesian_grid()
		ISOMETRIC:
			draw_isometric_grid()
	
	if zoom_at >= show_pixel_grid_at_zoom:
		draw_pixel_grid()


func draw_cartesian_grid():
	var grid_multiline_points := PackedVector2Array()

	var x :float = (rect.position.x + fposmod(rect.position.x, grid_size.x))
	while x <= rect.end.x:
		grid_multiline_points.push_back(Vector2(x, rect.position.y))
		grid_multiline_points.push_back(Vector2(x, rect.end.y))
		x += grid_size.x

	var y :float = (rect.position.y + fposmod(rect.position.y, grid_size.y))
	while y <= rect.end.y:
		grid_multiline_points.push_back(Vector2(rect.position.x, y))
		grid_multiline_points.push_back(Vector2(rect.end.x, y))
		y += grid_size.y

	if not grid_multiline_points.is_empty():
		draw_multiline(grid_multiline_points, grid_color)


func draw_isometric_grid():
	var grid_multiline_points = PackedVector2Array()

	var cell_size = isometric_grid_size
	var max_cell_count = rect.size / cell_size
	var origin_offset = Vector2(rect.position).posmodv(cell_size)

	# lines ↗↗↗ (from bottom-left to top-right)
	var per_cell_offset = cell_size * Vector2i(1, -1)

	#  lines ↗↗↗ starting from the rect's left side (top to bottom):
	var y :float = fposmod(
		origin_offset.y + cell_size.y * (0.5 + origin_offset.x / cell_size.x),
		cell_size.y)
		
	while y < rect.size.y:
		var start :Vector2 = Vector2(rect.position) + Vector2(0, y)
		var cells_to_rect_bounds = minf(max_cell_count.x, y / cell_size.y)
		var end = start + cells_to_rect_bounds * per_cell_offset
		grid_multiline_points.push_back(start)
		grid_multiline_points.push_back(end)
		y += cell_size.y

	#  lines ↗↗↗ starting from the rect's bottom side (left to right):
	var x :float = (y - rect.size.y) / cell_size.y * cell_size.x
	while x < rect.size.x:
		var start :Vector2 = Vector2(rect.position) + Vector2(x, rect.size.y)
		var cells_to_rect_bounds = minf(max_cell_count.y, 
										max_cell_count.x - x / cell_size.x)
		var end :Vector2 = start + cells_to_rect_bounds * per_cell_offset
		grid_multiline_points.push_back(start)
		grid_multiline_points.push_back(end)
		x += cell_size.x

	# lines ↘↘↘ (from top-left to bottom-right)
	per_cell_offset = cell_size

	#  lines ↘↘↘ starting from the rect's left side (top to bottom):
	y = fposmod(
		origin_offset.y - cell_size.y * (0.5 + origin_offset.x / cell_size.x),
		cell_size.y)
		
	while y < rect.size.y:
		var start :Vector2 = Vector2(rect.position) + Vector2(0, y)
		var cells_to_rect_bounds = minf(
			max_cell_count.x, max_cell_count.y - y / cell_size.y)
		var end :Vector2 = start + cells_to_rect_bounds * per_cell_offset
		grid_multiline_points.push_back(start)
		grid_multiline_points.push_back(end)
		y += cell_size.y

	#  lines ↘↘↘ starting from the rect's top side (left to right):
	var _x = origin_offset.x - cell_size.x * \
			 (0.5 + origin_offset.y / cell_size.y)
	x = fposmod(_x, cell_size.x)
	while x < rect.size.x:
		var start :Vector2 = Vector2(rect.position) + Vector2(x, 0)
		var cells_to_rect_bounds = minf(max_cell_count.y,
										max_cell_count.x - x / cell_size.x)
		var end :Vector2 = start + cells_to_rect_bounds * per_cell_offset
		grid_multiline_points.push_back(start)
		grid_multiline_points.push_back(end)
		x += cell_size.x

	if not grid_multiline_points.is_empty():
		draw_multiline(grid_multiline_points, isometric_grid_color)


func draw_pixel_grid():
	var grid_multiline_points = PackedVector2Array()
	for x in range(ceili(rect.position.x), floori(rect.end.x) + 1):
		grid_multiline_points.push_back(Vector2(x, rect.position.y))
		grid_multiline_points.push_back(Vector2(x, rect.end.y))

	for y in range(ceili(rect.position.y), floori(rect.end.y) + 1):
		grid_multiline_points.push_back(Vector2(rect.position.x, y))
		grid_multiline_points.push_back(Vector2(rect.end.x, y))

	if not grid_multiline_points.is_empty():
		draw_multiline(grid_multiline_points, pixel_grid_color)
