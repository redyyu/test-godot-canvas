class_name PickColor extends RefCounted

signal color_picked(color)

const DEFAULT_COLOR := Color.BLACK

var image := Image.new()


func blend_image(img_queue:Array, img_format:=Image.FORMAT_RGBA8):
	if img_queue.size() == 1:
		image.copy_from(img_queue[0])
		if image.get_format() != img_format:
			image.convert(img_format)
	elif img_queue.size() > 1:
		var bl_img := Image.create(1, 1, false, img_format)
		for img in img_queue:
			if img.get_size() != bl_img.get_size():
				bl_img.crop(img.get_width(), img.get_height())
			if img.get_format() != img_format:
				img.convert(img_format)
			var img_rect := Rect2i(Vector2i.ZERO, img.get_size())
			bl_img.blit_rect(img, img_rect, Vector2i.ZERO)
		image.copy_from(bl_img)


func pick(pos :Vector2i):
	var img_rect = Rect2i(Vector2i.ZERO, image.get_size())
	var picked_color := DEFAULT_COLOR
	if img_rect.has_point(pos):
		var c = image.get_pixelv(pos)
		picked_color = Color(c.r, c.g, c.b, 1)
	color_picked.emit(picked_color)

