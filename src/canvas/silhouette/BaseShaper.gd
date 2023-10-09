class_name BaseShaper extends RefCounted


var silhouette : Silhouette

var points :PackedVector2Array = []

var is_shaping := false
var is_moving := false

var is_operating :bool :
	get: return is_shaping or is_moving


func _init(_silhouette :Silhouette):
	silhouette = _silhouette


func reset():
	points.clear()
	is_shaping = false
	is_moving = false


func shaping_begin(pos :Vector2i):
	reset()
	if silhouette.has_point(pos):
		is_moving = true
	else:
		is_shaping = true
		points.append(pos)


func shaping(_pos :Vector2i):
	pass


func move_to(to_pos :Vector2i, use_pivot := true):
	silhouette.move_to(to_pos, use_pivot)


func resize_to(to_size:Vector2i):
	silhouette.resize_to(to_size)
