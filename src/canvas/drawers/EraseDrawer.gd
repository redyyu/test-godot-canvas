class_name EraseDrawer extends PixelDrawer

var shadow_image := Image.new()


class EraseOp extends BaseDrawer.ColorOp:
	
	const ERASE_COLOR := Color.TRANSPARENT
	
	func process(dst: Color) -> Color:
		if dst:
			return dst.lerp(ERASE_COLOR, strength)
		return ERASE_COLOR


func _init():
	color_op = EraseOp.new()
	allow_dyn_stroke_width = true
	allow_dyn_stroke_alpha = true


func reset():
	shadow_image.copy_from(image)
	

func draw_pixel(position: Vector2i):
	if not can_draw(position):
		return
	var color_old := shadow_image.get_pixelv(position)
	var drawing_color :Color = color_op.process(color_old)

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


func draw_start(pos: Vector2i):
	reset()
	super.draw_start(pos)
