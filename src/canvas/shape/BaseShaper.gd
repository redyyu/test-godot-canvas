class_name BaseShaper extends RefCounted


var size := Vector2i.ZERO
var canvas_rect :Rect2i :
	get: return Rect2i(Vector2i.ZERO, size)

var points :PackedVector2Array = []

var is_shaping := false
var is_moving := false

var is_operating :bool :
	get: return is_shaping or is_moving


func _init(_size :Vector2i):
	size = _size


func reset():
	points.clear()
	is_shaping = false
	is_moving = false


func shape_start(pos :Vector2i):
	reset()
	if canvas_rect.has_point(pos):
		points.append(pos)
		is_shaping = true


func shape_move(pos :Vector2i):
	if not is_operating:
		shape_start(pos)


func shape_end(_pos :Vector2i):
	is_shaping = false
	is_moving = false

