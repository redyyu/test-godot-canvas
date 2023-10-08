class_name PencilDrawer extends PixelDrawer

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
var pixel_perfect := true

var drawn_points :PackedVector2Array = []
var fill_inside := false

var i:= 0

class PencilOp extends BaseDrawer.ColorOp:
	func process(src: Color) -> Color:
		# take place to do something if need.
		# already have a BrushDrawer for drawing with strength / alpha.
		return src


func _init(sel_mask :Image):
	mask = sel_mask
	color_op = PencilOp.new()
	

func reset():
	drawn_points = []
	last_pixels = [null, null]


func draw_pixel(position: Vector2i):
	if not can_draw(position):
		return
	var old_color = image.get_pixelv(position)
	var drawing_color :Color = color_op.process(stroke_color)
	
	if stroke_width_dynamics > 1:
		var start := position - Vector2i.ONE * (stroke_width_dynamics >> 1)
		var end := start + Vector2i.ONE * stroke_width_dynamics
		var rect := Rect2i(start, end - start)
		if mask.is_empty() or mask.is_invisible():
			image.fill_rect(rect, drawing_color)
		else:
			draw_blit(Rect2i(start, end - start), image, mask, drawing_color)
	else:
		image.set_pixelv(position, drawing_color)

	if pixel_perfect and stroke_width_dynamics == 1:
		last_pixels.push_back([position, old_color])
		var corner = last_pixels.pop_front()
		var neighbour = last_pixels[0]

		if corner == null or neighbour == null:
			return
		
		var pos = position  # for short the line only.
		
		if (pos - corner[0]) in CORNERS and (pos - neighbour[0]) in NEIGHBOURS:
			var perfect_coord = Vector2i(neighbour[0].x, neighbour[0].y)
			var perfect_color = neighbour[1]
			if can_draw(perfect_coord):
				image.set_pixelv(perfect_coord, perfect_color)
			last_pixels[0] = corner


func draw_start(pos: Vector2i):
	reset()
	super.draw_start(pos)
	if fill_inside:
		drawn_points.append(pos)


func draw_move(pos: Vector2i):
	super.draw_move(pos)
	
	if fill_inside:
		drawn_points.append(pos)


func draw_end(pos: Vector2i):
	super.draw_end(pos)
	
	if fill_inside:
		drawn_points.append(pos)
		if drawn_points.size() <= 3:
			return
		var v := Vector2i()
		for x in image.get_width():
			v.x = x
			for y in image.get_height():
				v.y = y
				if Geometry2D.is_point_in_polygon(v, drawn_points):
					if draw_spacing_mode:
						v = get_spacing_position(v)
					draw_pixel(v)
