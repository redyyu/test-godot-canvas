class_name RectSelector extends PixelSelector

var selected_color :Color
var image := Image.new()
var image_rect :Rect2i :
	get: 
		if image.is_empty():
			return Rect2i()
		else:
			var img_size := Vector2i(image.get_width(), image.get_height())
			return Rect2i(Vector2i.ZERO, img_size)

func select_move(pos :Vector2i):
	super.select_move(pos)
	
	if is_selecting:
		points.clear()
		if image_rect.has_point(pos):
			var color := image.get_pixelv(pos)
			for x in image.get_width():
				for y in image.get_height():
					var p := Vector2i(x, y)
					if image.get_pixelv(p) == color:
						points.append(p)
	elif is_moving:
		move_to(pos)


func select_end(pos):
	if is_selecting:
		selection.selected_magic(points)
	super.select_end(pos)
