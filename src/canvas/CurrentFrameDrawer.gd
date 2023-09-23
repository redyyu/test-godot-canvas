extends Node2D

var img_texture := ImageTexture.new()
var opacity := 1.0


func update_(_texture, _opacity :=1.0):
	img_texture = _texture
	opacity = _opacity
	queue_redraw()
	

func _draw():
	draw_texture(img_texture, Vector2.ZERO, Color(1, 1, 1, opacity))
