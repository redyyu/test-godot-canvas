class_name PickColor extends RefCounted

signal color_picked(color)


func pick(image: Image, pos :Vector2i):
	var image_size = Vector2i(image.get_width(), image.get_height())
	var image_rect = Rect2i(Vector2i.ZERO, image_size)
	var picked_color := Color.BLACK
	if image_rect.has_point(pos):
		var color = image.get_pixelv(pos)
		picked_color = Color(color.r, color.g, color.b, 1)
	color_picked.emit(picked_color)
	picked_color = Color.BLACK

