class_name Cropper extends Node2D
# Draws the rectangle overlay for the crop tool
# Stores the shared settings between left and right crop tools

signal updated(rect)
signal applied(rect)
signal canceled(rect)
signal cursor_updated(cursor)

const BG_COLOR := Color(0, 0, 0, 0.66)
const LINE_COLOR := Color.WHITE

var sizer := GizmoSizer.new()
var pivot :
	get: return sizer.pivot
	set(val): sizer.pivot = val
var relative_position :Vector2i :
	get: return sizer.relative_position
	
var size := Vector2i.ZERO
var cropped_rect = Rect2i(0, 0, 0, 0) :
	set(val):
		cropped_rect = val
		queue_redraw()

var zoom_ratio := 1.0 :
	set(val):
		zoom_ratio = val
		sizer.zoom_ratio = zoom_ratio
		queue_redraw()

var is_cropping := false
var is_dragging := false


func _init():
	sizer.gizmo_hover_updated.connect(_on_sizer_hover_updated)
	sizer.gizmo_press_updated.connect(_on_sizer_press_updated)
	sizer.updated.connect(_on_sizer_updated)
	sizer.drag_started.connect(_on_sizer_drag_started)
	sizer.drag_ended.connect(_on_sizer_drag_ended)
	

func _ready():
	visible = false
	add_child(sizer)
	

func reset():
	visible = false
	is_cropping = false
	is_dragging = false
	cropped_rect.position = Vector2i.ZERO
	cropped_rect.size = size


func launch():
	sizer.attach(cropped_rect, true)
	visible = true


func cancel():
	sizer.dismiss()
	canceled.emit(cropped_rect)
	reset()


func apply(use_reset:=false):
	sizer.dismiss()
	if cropped_rect.has_area():
		applied.emit(cropped_rect)
	else:
		canceled.emit(cropped_rect)
	if use_reset:
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


func _on_sizer_hover_updated(gizmo, status):
	cursor_updated.emit(gizmo.cursor if status else null)


func _on_sizer_press_updated(_gizmo, status):
	is_cropping = status


func _on_sizer_updated(rect):
	cropped_rect = rect
	updated.emit(rect)
	

func _on_sizer_drag_started():
	is_dragging = true
	
func _on_sizer_drag_ended():
	is_dragging = false


# external injector

func inject_rect(rect :Rect2i):
	sizer.refresh(rect)
	# pass to sizer only, sizer will take care of many things, suck as pivot.
	# wait sizer finish the job, it will emit a event to Cropper.


func inject_sizer_snapping(call_snapping:Callable):
	sizer.get_snapping_weight = call_snapping
