class_name FreeTransformer extends Node2D

const MODULATE_COLOR := Color(1, 1, 1, 0.66)

var image := Image.new()
var canvas_size := Vector2i.ZERO
var transform_rect := Rect2i(Vector2i.ZERO, Vector2.ZERO)


func lanuch(src_img :Image, src_rect :Rect2i):
	if src_rect.has_area():
		transform_rect = src_rect
	else:
		transform_rect = src_img.get_used_rect()
	
	if transform_rect.has_area():
		image = src_img.get_region(transform_rect)
	


func has_image() -> bool:
	return not image.is_empty() and not image.is_invisible()


func _draw():
	if has_image() and transform_rect.has_area():
		var texture = ImageTexture.create_from_image(image)
		draw_texture_rect(texture, transform_rect, false, MODULATE_COLOR)
