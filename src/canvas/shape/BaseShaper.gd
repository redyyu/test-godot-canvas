class_name BaseShaper extends RefCounted


var shaping_area : ShapingArea

var points :PackedVector2Array = []

var is_shaping := false
var is_moving := false

var is_operating :bool :
	get: return is_shaping or is_moving


func _init(shape :ShapingArea):
	shaping_area = shape


func reset():
	points.clear()
	is_shaping = false
	is_moving = false


func shape_start(pos :Vector2i):
	if shaping_area.has_point(pos):
		is_moving = true
	else:
		reset()
		is_shaping = true
		points.append(pos)


func shape_move(pos :Vector2i):
	if not is_operating:
		shape_start(pos)


func shape_end(_pos :Vector2i):
	is_shaping = false
	is_moving = false


func move_to(to_pos :Vector2i, use_pivot := true):
	shaping_area.move_to(to_pos, use_pivot)


func resize_to(to_size:Vector2i):
	shaping_area.resize_to(to_size)
