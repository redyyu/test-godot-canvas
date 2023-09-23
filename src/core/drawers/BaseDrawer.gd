extends RefCounted

class_name BaseDrawer

var horizontal_mirror := false
var vertical_mirror := false
var color_op := ColorOp.new()


class ColorOp:
	var strength := 1.0

	func process(src: Color, _dst: Color) -> Color:
		return src


func set_pixel(image: Image, position: Vector2i, color: Color):
	var color_old := image.get_pixelv(position)
	var color_new := color_op.process(Color(color), color_old)
	if not color_new.is_equal_approx(color_old):
		image.set_pixelv(position, color_new)
