class_name Bucket extends RefCounted

signal color_filled

const NEIGHBOURS: PackedVector2Array = [
		Vector2.DOWN,
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.UP,
	]

var image := Image.new()
var image_rect :Rect2i :
	get: return Rect2i(Vector2i.ZERO, image.get_size())

var mask := Image.new()

var fill_color := Color.BLACK

var tolerance := 0 :
	set(val):
		tolerance = clampi(val, 0, 100)

var opt_contiguous := true


func _init(sel_mask):
	mask = sel_mask
	

func attach(img :Image):
	image = img


func fill(pos :Vector2i):
	if not image_rect.has_point(pos):
		return
	if mask.is_empty() or mask.is_invisible():
		var target_color = image.get_pixelv(pos)
		if opt_contiguous:
			fill_to_color_contiguous(pos, target_color)
		else:
			fill_to_color(target_color)
	else:
		fill_selection()
	
	color_filled.emit()
	

func fill_selection():
	var fill_rect = mask.get_used_rect()
	for x in range(fill_rect.position.x, fill_rect.end.x):
		for y in range(fill_rect.position.y, fill_rect.end.y):
			var p := Vector2i(x, y)
			image.set_pixelv(p, fill_color)


func fill_to_color(target_color :Color):
	for x in image.get_width():
		for y in image.get_height():
			var p := Vector2i(x, y)
			var p_color = image.get_pixelv(p)
			if is_matched(p_color, target_color):
				image.set_pixelv(p, fill_color)


func fill_to_color_contiguous(pos :Vector2i, target_color :Color):
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
		
		image.set_pixelv(p, fill_color)

		for n in NEIGHBOURS:
			var np = p + n
			if rect.has_point(np) and not visited.has(np):
				visited[np] = true
				var np_color = image.get_pixelv(np)
				if is_matched(np_color, target_color):
					queue.append(np)


func is_matched(img_color :Color, target_color :Color):
	if target_color.is_equal_approx(img_color):
		return true
	elif tolerance > 0:
		var diff = target_color - img_color
		var t = tolerance / 100.0
		diff.r = abs(diff.r)
		diff.g = abs(diff.g)
		diff.b = abs(diff.b)
		diff.a = abs(diff.a)
		return diff.r < t and diff.g < t and diff.b < t and diff.a < t
