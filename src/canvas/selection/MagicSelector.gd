class_name MagicSelector extends PixelSelector

const NEIGHBOURS: PackedVector2Array = [
		Vector2.DOWN,
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.UP,
	]

var image := Image.new()
var image_rect :Rect2i :
	get: return Rect2i(Vector2i.ZERO, image.get_size())

var selected_color = null
var start_position = null

var tolerance := 0:
	set = set_tolerance

var opt_contiguous := false


func set_tolerance(val):
	if val != tolerance:
		tolerance = clampi(val, 0, 100)


func select_start(pos):
	if image_rect.has_point(pos):  # make sure in the image, because get pixel.
		super.select_start(pos)
		selected_color = image.get_pixelv(pos)
		start_position = pos


func select_move(pos :Vector2i):
	super.select_move(pos)
		
	if is_selecting and points.size() > 0:
		# check points size for make sure select_start is runned.
		# first point is record from select_start.
		if opt_contiguous:
			matching_contiguous(points[0])
		else:
			matching_all(points[0])
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
			var p_color = image.get_pixelv(p)
			if is_matched_color(p_color):
				points.append(p)


func matching_contiguous(pos :Vector2i):
	var queue :PackedVector2Array = []
	var visited :Dictionary = {}
	var rect :Rect2 = image_rect
	queue.append(pos)
	visited[pos] = true
	while queue:
		var i = queue.size() - 1
		var p = queue[i]
		queue.remove_at(i)  # remove from last, is much much faster.
		# DOC says: On large arrays, this method will be slower if the removed 
		# element is close to the beginning of the array (index 0). 
		# This is because all elements placed after the removed element
		# have to be reindexed.
		
		points.append(p)
		# no need check duplicated here, each time check p is in points or not
		# will cause lot of performance when points goes large.
		# beside, only first point will be duplicated.

		for n in NEIGHBOURS:
			var np = p + n
			if rect.has_point(np) and not visited.has(np):
				visited[np] = true
				var np_color = image.get_pixelv(np)
				if is_matched_color(np_color):
					queue.append(np)


func is_matched_color(img_color :Color):
	if not selected_color is Color or not img_color is Color:
		return false
	if selected_color.is_equal_approx(img_color):
		return true
	elif tolerance > 0:
		var diff = selected_color - img_color
		var t = tolerance / 100.0
		diff.r = abs(diff.r)
		diff.g = abs(diff.g)
		diff.b = abs(diff.b)
		diff.a = abs(diff.a)
		return diff.r < t and diff.g < t and diff.b < t and diff.a < t
