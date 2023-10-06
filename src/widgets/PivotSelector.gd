@tool

class_name PivotSelector extends Control

signal pivot_updated(pivot)

enum Pivot {
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

@export var pivot := Pivot.TOP_LEFT:
	set(val):
		pivot = val
		set_pivots()
		pivot_updated.emit(pivot)

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
	set_pivots()


func set_pivots():
	pivot_points.clear()
	for i in Pivot:
		var id = Pivot[i]
		var pos = get_pivot_position(id)
		pivot_points.append({
			'id': id,
			'position': pos,
			'rect': Rect2i(pos - pivot_touch_size / 2, pivot_touch_size),
			'color': pivot_on_color if pivot == id else pivot_color
		})
	queue_redraw()


func get_pivot_position(id) -> Vector2i:
	match id:
		Pivot.TOP_LEFT:
			return Vector2.ZERO + pivot_size * 1.0
		Pivot.TOP_CENTER:
			return Vector2(size.x * 0.5, pivot_size.y)
		Pivot.TOP_RIGHT:
			return Vector2(size.x - pivot_size.x, pivot_size.y)
		Pivot.MIDDLE_RIGHT:
			return Vector2(size.x - pivot_size.x, size.y * 0.5)
		Pivot.BOTTOM_RIGHT:
			return Vector2(size.x - pivot_size.x, size.y - pivot_size.y)
		Pivot.BOTTOM_CENTER:
			return Vector2(size.x * 0.5, size.y - pivot_size.y)
		Pivot.BOTTOM_LEFT:
			return Vector2(pivot_size.x, size.y - pivot_size.y)
		Pivot.MIDDLE_LEFT:
			return Vector2(pivot_size.x, size.y * 0.5)
		_: # Pivot.CENTER
			return Vector2(size.x * 0.5, size.y * 0.5)



func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var pos = get_local_mouse_position()
		for p in pivot_points:
			if p['rect'].has_point(pos):
				pivot = p['id']
				break


func _draw():
	draw_rect(frame_rect, line_color, false, line_weight)
	for p in pivot_points:
		draw_circle(p['position'], pivot_point_radius, p['color'])
		
	
