class_name CropRect extends ColorRect
# Draws the rectangle overlay for the crop tool
# Stores the shared settings between left and right crop tools

signal updated
signal applied

const DARKEN_COLOR := Color(0, 0, 0, 0.5)
const LINE_COLOR := Color.WHITE

var ratio_locked := false

var crop_rect = Rect2i(0, 0, 0, 0)

var zoom_ratio := 1.0:
	set(val):
		zoom_ratio = val
		

func _draw() -> void:
	# Rect:
	draw_rect(crop_rect, LINE_COLOR, false, 1.0 / zoom_ratio)

	# Horizontal rule of thirds lines:
	var third: float = crop_rect.position.y + crop_rect.size.y * 0.333
	draw_line(Vector2(crop_rect.position.x, third), 
			  Vector2(crop_rect.end.x, third),
			  LINE_COLOR, 1.0 / zoom_ratio)
			
	third = crop_rect.position.y + crop_rect.size.y * 0.667
	draw_line(Vector2(crop_rect.position.x, third),
			  Vector2(crop_rect.end.x, third),
			  LINE_COLOR, 1.0 / zoom_ratio)

	# Vertical rule of thirds lines:
	third = crop_rect.position.x + crop_rect.size.x * 0.333
	draw_line(Vector2(third, crop_rect.position.y),
			  Vector2(third, crop_rect.end.y),
			  LINE_COLOR, 1.0 / zoom_ratio)
			
	third = crop_rect.position.x + crop_rect.size.x * 0.667
	draw_line(Vector2(third, crop_rect.position.y),
			  Vector2(third, crop_rect.end.y),
			  LINE_COLOR, 1.0 / zoom_ratio)


func apply_crop() -> void:
	applied.emit(crop_rect)
