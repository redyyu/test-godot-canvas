extends Node2D

const SHOW_AT_ZOOM :float = 1500.

var camera_zoom: Vector2 = Vector2.ZERO
var grid_color :Color = Color("21212191")
var draw_pixel_grid :bool = false


func _draw():
	if not draw_pixel_grid:
		return

	if (100.0 * camera_zoom.x) < SHOW_AT_ZOOM:
		return

	var target_rect = g.current_project.tiles.get_bounding_rect()
	if not target_rect.has_area():
		return

	var grid_multiline_points = PackedVector2Array()
	for x in range(ceili(target_rect.position.x), floori(target_rect.end.x) + 1):
		grid_multiline_points.push_back(Vector2(x, target_rect.position.y))
		grid_multiline_points.push_back(Vector2(x, target_rect.end.y))

	for y in range(ceili(target_rect.position.y), floori(target_rect.end.y) + 1):
		grid_multiline_points.push_back(Vector2(target_rect.position.x, y))
		grid_multiline_points.push_back(Vector2(target_rect.end.x, y))

	if not grid_multiline_points.is_empty():
		draw_multiline(grid_multiline_points, grid_color)
