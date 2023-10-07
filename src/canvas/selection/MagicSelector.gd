class_name MagicSelector extends PixelSelector

const NEIGHBOURS: Array[Vector2i] = [
		Vector2i.DOWN,
		Vector2i.RIGHT,
		Vector2i.LEFT,
		Vector2i.UP,
	]
	
var processed_points :PackedVector2Array = []

var image := Image.new()
var image_rect :Rect2i :
	get: return Rect2i(Vector2i.ZERO, image.get_size())

var selected_color = null

var tolerance := 0:
	set = set_tolerance

var opt_contiguous := false


func set_tolerance(val):
	if val != tolerance:
		tolerance = clampi(val, 0, 100)


func reset():
	super.reset()
	processed_points.clear()


func select_start(pos):
	super.select_start(pos)
	if image_rect.has_point(pos):
		selected_color = image.get_pixelv(pos)


func select_move(pos :Vector2i):
	super.select_move(pos)
	
	if is_selecting and selected_color is Color:
		if opt_contiguous:
			matching_contiguous_recursion(pos)
		else:
			matching_all(pos)
			
	elif is_moving:
		move_to(pos)


func select_end(pos):
	if is_selecting:
		selection.selected_magic(points)
	super.select_end(pos)


func matching_all(pos):
	if not image_rect.has_point(pos):
		return
		
	for x in image.get_width():
		for y in image.get_height():
			var p := Vector2i(x, y)
			if match_color(selected_color, p):
				points.append(p)


func matching_contiguous_recursion(pos :Vector2i):
	var nearest_points = get_nearest_points(pos)
	for np in nearest_points:
		if match_color(selected_color, np):
			matching_contiguous_recursion(np)
			points.append(np)


func get_nearest_points(pos):
	var nearest_points :PackedVector2Array = []
	for p in NEIGHBOURS:
		var np :Vector2 = pos + p
		if not processed_points.has(np) and image_rect.has_point(np):
			nearest_points.append(np)
			processed_points.append(np)
	return nearest_points


func match_color(color :Color, pos :Vector2i):
	var img_color = image.get_pixelv(pos) 
	if color.is_equal_approx(img_color):
		return true
	elif tolerance > 0:
		var diff = color - img_color
		var t = tolerance / 100.0
		return diff.r < t and diff.g < t and diff.b < t and diff.a < t
