class_name FreeTransformer extends Node2D

const MODULATE_COLOR := Color(1, 1, 1, 0.66)

var image := Image.new()
var canvas_size := Vector2i.ZERO
var move_rect := Rect2i(Vector2i.ZERO, Vector2.ZERO)



func has_image() -> bool:
	return not image.is_empty() and not image.is_invisible()


func _draw():
	if has_image() and move_rect.has_area():
		var texture = ImageTexture.create_from_image(image)
		draw_texture_rect(texture, move_rect, false, MODULATE_COLOR)
		
