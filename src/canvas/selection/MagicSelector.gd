class_name MagicSelector extends PixelSelector

var image := Image.new()
var image_rect :Rect2i :
	get: return Rect2i(Vector2i.ZERO, image.get_size())

var tolerance := 0:
	set = set_tolerance


func set_tolerance(val):
	if val != tolerance:
		tolerance = clampi(val, 0, 100)


func select_move(pos :Vector2i):
	super.select_move(pos)
	if is_selecting:
		points = matching_points(pos)
	elif is_moving:
		move_to(pos)


func select_end(pos):
	if is_selecting:
		selection.selected_magic(points)
	super.select_end(pos)


func matching_points(pos):
	var matched_points :PackedVector2Array = []
	if image_rect.has_point(pos):
		var color := image.get_pixelv(pos)
		for x in image.get_width():
			for y in image.get_height():
				var p := Vector2i(x, y)
				if match_color(color, p):
					matched_points.append(p)
	return matched_points


func match_color(color :Color,  p :Vector2i):
	var img_color = image.get_pixelv(p) 
	if color.is_equal_approx(img_color):
		return true
	elif tolerance > 0:
		var diff = color - img_color
		var t = tolerance / 100.0
		return diff.r < t and diff.g < t and diff.b < t and diff.a < t
			
		
	
