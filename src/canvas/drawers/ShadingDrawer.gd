class_name ShadingDrawer extends PixelDrawer

# shadow_image use for pickup old color while draw, 
# copy from image every time when draw_start.
# to prevent old color pickup from just drawn pixel.
# this is for make color blending work.
var shadow_image := Image.new() 

var last_pixels := [null, null]
var pixel_perfect := true

var shading_op := ShadingOp.new()

var op_simple_shading :bool :
	get: return shading_op.as_simple_shading
	set(val): shading_op.as_simple_shading = val

var op_lighten :bool :
	get: return shading_op.as_ligthen
	set(val): shading_op.as_lighten = val

var op_hue_amount :float :
	get: return shading_op.hue_amount
	set(val): shading_op.hue_amount = val

var op_sat_amount :float :
	get: return shading_op.sat_amount
	set(val): shading_op.sat_amount = val

var op_value_amount :float :
	get: return shading_op.value_amount
	set(val): shading_op.value_amount = val
	
var op_strength :float:
	get: return shading_op.strength
	set(val): shading_op.strength = val


class ShadingOp extends BaseDrawer.ColorOp:
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
	stroke_width = 12
	

func reset():
	shadow_image.copy_from(image)


func draw_pixel(position: Vector2i):
	if not can_draw(position):
		return
	var old_color = shadow_image.get_pixelv(position)
	var drawing_color :Color = shading_op.process(stroke_color, old_color)
	
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


func draw_start(pos: Vector2i):
	reset()
	super.draw_start(pos)

