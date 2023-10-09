@tool

class_name PivotSelector extends Control

signal pivot_updated(pivot)

enum PivotPoint {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	MIDDLE_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_CENTER,
	BOTTOM_LEFT,
	MIDDLE_LEFT,
	CENTER,
}

@export var pivot_value := PivotPoint.TOP_LEFT:
	set = pivot_changed

@export var pivot_point_radius := 5
@export var pivot_frame_color := Color.DIM_GRAY
@export var pivot_on_color := Color.WHITE
@export var pivot_color := Color.DARK_GRAY

@export var line_color := Color.DIM_GRAY
@export var line_weight := 2

@export var _size := Vector2i(64, 64)

var pivot_points :Array[Dictionary] = []

var pivot_size :Vector2i :
	get: return Vector2i(pivot_point_radius * 2, pivot_point_radius * 2)

var pivot_touch_size :Vector2i :
	get: return _size / 3

var frame_rect :Rect2i :
	get: return Rect2i(Vector2i.ZERO + pivot_size,
					   Vector2i(_size) - pivot_size * 2)

func _init():
	size = _size
	custom_minimum_size = _size


func _ready():
	prepare_pivots()


func pivot_changed(val):
	if pivot_value != val:
		pivot_value = val
		pivot_updated.emit(pivot_value)
		prepare_pivots()
	

func prepare_pivots():	
	pivot_points.clear()
	for i in PivotPoint:
		var id = Pivot[i]
		var pos = get_pivot_position(id)
		pivot_points.append({
			'id': id,
			'position': pos,
			'rect': Rect2i(pos - pivot_touch_size / 2, pivot_touch_size),
			'color': pivot_on_color if pivot_value == id else pivot_color
		})
	queue_redraw()


func get_pivot_position(id) -> Vector2i:
	match id:
		PivotPoint.TOP_LEFT:
			return Vector2.ZERO + pivot_size * 1.0
		PivotPoint.TOP_CENTER:
			return Vector2(size.x * 0.5, pivot_size.y)
		PivotPoint.TOP_RIGHT:
			return Vector2(size.x - pivot_size.x, pivot_size.y)
		PivotPoint.MIDDLE_RIGHT:
			return Vector2(size.x - pivot_size.x, size.y * 0.5)
		PivotPoint.BOTTOM_RIGHT:
			return Vector2(size.x - pivot_size.x, size.y - pivot_size.y)
		PivotPoint.BOTTOM_CENTER:
			return Vector2(size.x * 0.5, size.y - pivot_size.y)
		PivotPoint.BOTTOM_LEFT:
			return Vector2(pivot_size.x, size.y - pivot_size.y)
		PivotPoint.MIDDLE_LEFT:
			return Vector2(pivot_size.x, size.y * 0.5)
		_: # PivotPoint.CENTER
			return Vector2(size.x * 0.5, size.y * 0.5)



func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var pos = get_local_mouse_position()
		for p in pivot_points:
			if p['rect'].has_point(pos):
				pivot_value = p['id']
				break


func _draw():
	draw_rect(frame_rect, line_color, false, line_weight)
	for p in pivot_points:
		draw_circle(p['position'], pivot_point_radius, p['color'])
