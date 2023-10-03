class_name CropRect extends Node2D
# Draws the rectangle overlay for the crop tool
# Stores the shared settings between left and right crop tools

signal updated
signal applied

const BG_COLOR := Color(0, 0, 0, 0.66)
const LINE_COLOR := Color.WHITE

var opt_as_square := false

var size := Vector2i.ZERO
var cropped_rect = Rect2i(0, 0, 0, 0)

var zoom_ratio := 1.0:
	set(val):
		zoom_ratio = val


func start_crop():
	cropped_rect.size = size
	hide()


func cancel_crop():
	hide()


func apply_crop() -> void:
	applied.emit(cropped_rect)
	hide()



func _draw() -> void:
	if not cropped_rect.has_area():
		return
		
	# Background
	draw_rect(Rect2(0, 0, size.x, cropped_rect.position.y), BG_COLOR)
	draw_rect(Rect2(cropped_rect.end.x, 
					cropped_rect.size.x, 
					size.x - cropped_rect.end.x,
					size.y - cropped_rect.end.y), BG_COLOR)
	draw_rect(Rect2(0, cropped_rect.end.y, 
					size.y - cropped_rect.end.y, 
					size.y), BG_COLOR)
	draw_rect(Rect2(0, cropped_rect.position.y,
					size.y - cropped_rect.end.y,
					size.x - cropped_rect.position.x), BG_COLOR)
	
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

