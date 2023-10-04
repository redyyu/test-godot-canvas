class_name CropRect extends Node2D
# Draws the rectangle overlay for the crop tool
# Stores the shared settings between left and right crop tools

signal canceled(rect)
signal applied(rect)

const BG_COLOR := Color(0, 0, 0, 0.66)
const LINE_COLOR := Color.WHITE

var opt_as_square := false

var size := Vector2i.ZERO
var cropped_rect = Rect2i(0, 0, 0, 0) :
	set(val):
		cropped_rect = val
		queue_redraw()

var zoom_ratio := 1.0 :
	set(val):
		zoom_ratio = val
		queue_redraw()

var start_position := Vector2i.ZERO
var is_cropping := false


func _ready():
	visible = false
	

func reset():
	visible = false
	is_cropping = false
	cropped_rect.position = Vector2i.ZERO
	cropped_rect.size = size


func launch():
	if not is_cropping:
		reset()
	is_cropping = true
	visible = true


func cancel():
	canceled.emit(cropped_rect)
	reset()


func apply(reset:=false):
	if cropped_rect.has_area():
		applied.emit(cropped_rect)
	else:
		canceled.emit(cropped_rect)
	if reset:
		reset()


func has_point(point :Vector2i) ->bool:
	return cropped_rect.has_point(point)


func _draw() -> void:
	if not cropped_rect.has_area():
		return
		
	# Background
	var total_rect = Rect2i(Vector2.ZERO, size)
	
	if cropped_rect.position.y > 0 and size.x > 0:
		var top_rect = total_rect.intersection(
			Rect2i(0, 0, size.x, cropped_rect.position.y))
		draw_rect(top_rect, BG_COLOR)
	
	if (size.x - cropped_rect.end.x) > 0 and cropped_rect.size.y > 0:
		var right_rect = total_rect.intersection(
			Rect2i(cropped_rect.end.x, cropped_rect.position.y, 
				   size.x - cropped_rect.end.x, cropped_rect.size.y))
		draw_rect(right_rect, BG_COLOR)
	
	if size.x > 0 and (size.y - cropped_rect.end.y) > 0:
		var bottom_rect = total_rect.intersection(
			Rect2i(0, cropped_rect.end.y, size.x, size.y - cropped_rect.end.y))
		draw_rect(bottom_rect, BG_COLOR)	
		
	if cropped_rect.position.x > 0 and cropped_rect.size.y > 0:
		var left_rect = total_rect.intersection(
			Rect2i(0, cropped_rect.position.y, 
				   cropped_rect.position.x, cropped_rect.size.y))
		draw_rect(left_rect, BG_COLOR)

	
	# Rect:
	draw_rect(cropped_rect, LINE_COLOR, false, 1.0 / zoom_ratio)

	# Horizontal rule of thirds lines:
	var third: float = cropped_rect.position.y + cropped_rect.size.y * 0.333
	draw_line(Vector2(cropped_rect.position.x, third), 
			  Vector2(cropped_rect.end.x, third),
			  LINE_COLOR, 1.0 / zoom_ratio)
			
	third = cropped_rect.position.y + cropped_rect.size.y * 0.667
	draw_line(Vector2(cropped_rect.position.x, third),
			  Vector2(cropped_rect.end.x, third),
			  LINE_COLOR, 1.0 / zoom_ratio)

	# Vertical rule of thirds lines:
	third = cropped_rect.position.x + cropped_rect.size.x * 0.333
	draw_line(Vector2(third, cropped_rect.position.y),
			  Vector2(third, cropped_rect.end.y),
			  LINE_COLOR, 1.0 / zoom_ratio)
			
	third = cropped_rect.position.x + cropped_rect.size.x * 0.667
	draw_line(Vector2(third, cropped_rect.position.y),
			  Vector2(third, cropped_rect.end.y),
			  LINE_COLOR, 1.0 / zoom_ratio)
