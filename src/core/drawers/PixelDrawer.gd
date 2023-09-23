extends BaseDrawer

class_name PixelDrawer

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

var last_pixels := [null, null]
var pixel_perfect := false

func reset():
	last_pixels = [null, null]


func draw_pixel(image: Image, position: Vector2i, color: Color):
	var rect = Rect2i(
		Vector2i.ZERO, 
		Vector2i(image.get_width(), image.get_height())
	)
				
	if not rect.has_point(position):
		return

	var color_old := image.get_pixelv(position)
	var color_new := color_op.process(Color(color), color_old)
	
	image.set_pixelv(position, color_new)
	
	if pixel_perfect:
		last_pixels.push_back([position, color_old])
		var corner = last_pixels.pop_front()
		var neighbour = last_pixels[0]

		if corner == null or neighbour == null:
			return
		
		var pos = position  # for short the line only.
		
		if (pos - corner[0]) in CORNERS and (pos - neighbour[0]) in NEIGHBOURS:
			image.set_pixel(neighbour[0].x, neighbour[0].y, neighbour[1])
			last_pixels[0] = corner
