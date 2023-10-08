class_name EraseDrawer extends PixelDrawer

var shadow_image := Image.new()


class EraseOp extends BaseDrawer.ColorOp:
	
	const ERASE_COLOR := Color.TRANSPARENT
	
	func process(dst: Color) -> Color:
		if dst:
			return dst.lerp(ERASE_COLOR, strength)
		return ERASE_COLOR


func _init(sel_mask :Image):
	mask = sel_mask
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
			draw_blit(Rect2i(start, end - start), image, mask, drawing_color)
	else:
		image.set_pixelv(position, drawing_color)


func draw_start(pos: Vector2i):
	reset()
	super.draw_start(pos)
