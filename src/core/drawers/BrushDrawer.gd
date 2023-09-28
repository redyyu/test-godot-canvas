class_name BrushDrawer extends BaseDrawer

const NEIGHBOURS: Array[Vector2i] = [
		Vector2i.DOWN,
		Vector2i.RIGHT,
		Vector2i.LEFT,
		Vector2i.UP
	]

const CORNERS: Array[Vector2i] = [
	Vector2i.ONE,
	-Vector2i.ONE,
	Vector2i(-1, 1),
	Vector2i(1, -1)
]

# shadow_image use for pickup old color while draw, 
# copy from image every time when draw_start.
# to prevent old color pickup from just drawn pixel.
# this is for make color blending work.
var shadow_image := Image.new() 

var last_pixels := [null, null]
var pixel_perfect := true

class BrushOp extends BaseDrawer.ColorOp:
	var blending := true
	# Drawing pixels might drawing same position many times.
	# the dst color to blend might be the src color just drawn.
	# thats the reason the color doesn't looks by effect pressure properly,	
	# Use a shadow image to backup previos color on the image is idea.
	# but that will cause last drawing point cast unexcpet alpha.
	# that's because still detected a weak pressure.
	
	func process(src: Color, dst: Color) -> Color:
		src.a *= strength
		if blending:
			return dst.blend(src)
		else:
			return src


func _init():
	allow_dyn_stroke_alpha = true
	allow_dyn_stroke_width = true
	color_op = BrushOp.new()
	stroke_width = 12
	

func reset():
	shadow_image.copy_from(image)


func draw_pixel(position: Vector2i):
	if not can_draw(position):
		return
	var old_color = shadow_image.get_pixelv(position)
	var drawing_color :Color = color_op.process(stroke_color, old_color)

	# for different stroke weight, draw pixel is one by one, 
	# even the stroke is large weight. actually its draw many pixel once.
	var coords_to_draw := PackedVector2Array()
	var start := position - Vector2i.ONE * (stroke_width_dynamics >> 1)
	var end := start + Vector2i.ONE * stroke_width_dynamics
	
	for y in range(start.y, end.y):
		for x in range(start.x, end.x):
			coords_to_draw.append(Vector2(x, y))
	for coord in coords_to_draw:
		if can_draw(coord):
			image.set_pixelv(coord, drawing_color)
#			shadow_image.set_pixelv(coord, drawing_color)


func draw_start(pos: Vector2i):
	reset()
#	pos = snap_position(pos)
	super.draw_start(pos)

