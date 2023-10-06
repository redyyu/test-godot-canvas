class_name BrushDrawer extends PixelDrawer

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

class ShadingOp extends BaseDrawer.ColorOp:
	var changed := false
	var as_simple_shading := true
	var as_lighten := false
	var hue_amount := 10.0
	var sat_amount := 10.0
	var value_amount := 10.0

	var hue_lighten_limit := 60.0 / 360.0  # yellow
	var hue_darken_limit := 240.0 / 360.0  # blue

	var sat_lighten_limit := 10.0 / 100.0
	var value_darken_limit := 10.0 / 100.0

	func process(_src: Color, dst: Color) -> Color:
		changed = true
		if dst.a == 0:
			return dst
		if as_simple_shading:
			if as_lighten:
				dst = dst.lightened(strength)
			else:
				dst = dst.darkened(strength)
		else:
			var hue_shift := hue_amount / 360.0
			var sat_shift := sat_amount / 100.0
			var value_shift := value_amount / 100.0

			# if the colors are roughly between yellow-green-blue,
			# reverse hue direction.
			if hue_range(dst.h):
				hue_shift = -hue_shift

			if as_lighten:
				hue_shift = hue_limit_lighten(dst.h, hue_shift)
				dst.h = fposmod(dst.h + hue_shift, 1)
				if dst.s > sat_lighten_limit:
					dst.s = maxf(dst.s - minf(sat_shift, dst.s), 
								 sat_lighten_limit)
				dst.v += value_shift

			else:
				hue_shift = hue_limit_darken(dst.h, hue_shift)
				dst.h = fposmod(dst.h - hue_shift, 1)
				dst.s += sat_shift
				if dst.v > value_darken_limit:
					dst.v = maxf(dst.v - minf(value_shift, dst.v),
								 value_darken_limit)

		return dst

	# returns true if the colors are roughly between yellow, green and blue
	# False when the colors are roughly between red-orange-yellow, 
	# or blue-purple-red.
	func hue_range(hue: float) -> bool:
		return hue > hue_lighten_limit and hue < hue_darken_limit

	func hue_limit_lighten(hue: float, hue_shift: float) -> float:
		# colors between red-orange-yellow and blue-purple-red
		if hue_shift > 0:
			# just colors between red-orange-yellow
			if hue < hue_darken_limit:
				if hue + hue_shift >= hue_lighten_limit:
					hue_shift = hue_lighten_limit - hue
			# just blue-purple-red
			else:
				if hue + hue_shift >= hue_lighten_limit + 1:
					# +1 looping around the color wheel
					hue_shift = hue_lighten_limit - hue

		# colors between yellow-green-blue
		elif hue_shift < 0 and hue + hue_shift <= hue_lighten_limit:
			hue_shift = hue_lighten_limit - hue
		return hue_shift

	func hue_limit_darken(hue: float, hue_shift: float) -> float:
		# colors between red-orange-yellow and blue-purple-red
		if hue_shift > 0:
			# just colors between red-orange-yellow
			if hue < hue_darken_limit:
				if hue - hue_shift <= hue_darken_limit - 1:
					# -1 looping backwards around the color wheel
					hue_shift = hue - hue_darken_limit
			
			else: # just blue-purple-red
				if hue - hue_shift <= hue_darken_limit:
					hue_shift = hue - hue_darken_limit

		# colors between yellow-green-blue
		elif hue_shift < 0 and hue - hue_shift >= hue_darken_limit:
			hue_shift = hue - hue_darken_limit
		return hue_shift



func _init():
	allow_dyn_stroke_alpha = true
	allow_dyn_stroke_width = true
	color_op = ShadingOp.new()
	stroke_width = 12
	

func reset():
	shadow_image.copy_from(image)


func draw_pixel(position: Vector2i):
	if not can_draw(position):
		return
	var old_color = shadow_image.get_pixelv(position)
	var drawing_color :Color = color_op.process(stroke_color, old_color)
	
	if stroke_width_dynamics > 1:
		var start := position - Vector2i.ONE * (stroke_width_dynamics >> 1)
		var end := start + Vector2i.ONE * stroke_width_dynamics
		var rect := Rect2i(start, end - start)
		if mask.is_empty() or mask.is_invisible():
			image.fill_rect(rect, drawing_color)
		else:
			var tmp_img = Image.create(image.get_width(), image.get_height(),
									   false, image.get_format())
			tmp_img.fill_rect(Rect2i(start, end - start), drawing_color)
			image.blit_rect_mask(tmp_img, mask, rect, start)
	else:
		image.set_pixelv(position, drawing_color)

#	DONT NEED those, already replace by blit_rect_mask for high performance.
#	the old way, is really slow, slow than slow horse when stroke size is big.
#
#	# for different stroke weight, draw pixel is one by one, 
#	# even the stroke is large weight. actually its draw many pixel once.
#	var coords_to_draw := PackedVector2Array()
#	var start := position - Vector2i.ONE * (stroke_width_dynamics >> 1)
#	var end := start + Vector2i.ONE * stroke_width_dynamics
#
#	for y in range(start.y, end.y):
#		for x in range(start.x, end.x):
#			coords_to_draw.append(Vector2(x, y))
#	for coord in coords_to_draw:
#		if can_draw(coord):
#			image.set_pixelv(coord, drawing_color)
##			shadow_image.set_pixelv(coord, drawing_color)


func draw_start(pos: Vector2i):
	reset()
	super.draw_start(pos)

