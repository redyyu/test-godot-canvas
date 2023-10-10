class_name CropSizer extends GizmoSizer

signal crop_canvas(rect)

const MASK_COLOR := Color(0, 0, 0, 0.66)

var size := Vector2i.ZERO


func _init():
	super._init()
	applied.connect(_on_applied)


func launch(canvas_size: Vector2i):
	frozen(false)
	size = canvas_size
	var rect := Rect2i(Vector2i.ZERO, size)
	attach(rect, true)


func cancel(use_reset := true):
	bound_rect = Rect2i(Vector2i.ZERO, size)
	super.cancel(use_reset)


func _draw():
	super._draw()
	
	if not has_area():
		return
	
	# Background
	var total_rect = Rect2i(Vector2.ZERO, size)
	
	if bound_rect.position.y > 0 and size.x > 0:
		var top_rect = total_rect.intersection(
			Rect2i(0, 0, size.x, bound_rect.position.y))
		draw_rect(top_rect, MASK_COLOR)
	
	if (size.x - bound_rect.end.x) > 0 and bound_rect.size.y > 0:
		var right_rect = total_rect.intersection(
			Rect2i(bound_rect.end.x, bound_rect.position.y, 
				   size.x - bound_rect.end.x, bound_rect.size.y))
		draw_rect(right_rect, MASK_COLOR)
	
	if size.x > 0 and (size.y - bound_rect.end.y) > 0:
		var bottom_rect = total_rect.intersection(
			Rect2i(0, bound_rect.end.y, size.x, size.y - bound_rect.end.y))
		draw_rect(bottom_rect, MASK_COLOR)	
		
	if bound_rect.position.x > 0 and bound_rect.size.y > 0:
		var left_rect = total_rect.intersection(
			Rect2i(0, bound_rect.position.y, 
				   bound_rect.position.x, bound_rect.size.y))
		draw_rect(left_rect, MASK_COLOR)


	# Horizontal rule of thirds lines:
	var third: float = bound_rect.position.y + bound_rect.size.y * 0.333
	draw_line(Vector2(bound_rect.position.x, third), 
			  Vector2(bound_rect.end.x, third),
			  line_color, line_width / zoom_ratio)
			
	third = bound_rect.position.y + bound_rect.size.y * 0.667
	draw_line(Vector2(bound_rect.position.x, third),
			  Vector2(bound_rect.end.x, third),
			  line_color, line_width / zoom_ratio)

	# Vertical rule of thirds lines:
	third = bound_rect.position.x + bound_rect.size.x * 0.333
	draw_line(Vector2(third, bound_rect.position.y),
			  Vector2(third, bound_rect.end.y),
			  line_color, line_width / zoom_ratio)
			
	third = bound_rect.position.x + bound_rect.size.x * 0.667
	draw_line(Vector2(third, bound_rect.position.y),
			  Vector2(third, bound_rect.end.y),
			  line_color, line_width / zoom_ratio)


func _on_applied(rect):
	crop_canvas.emit(rect)

