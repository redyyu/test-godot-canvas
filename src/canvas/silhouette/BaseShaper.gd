class_name BaseShaper extends RefCounted


var silhouette : Silhouette
var moving_offset := Vector2i.ZERO

var points :PackedVector2Array = []

var last_position :Variant = null # prevent same with mouse pos from beginning.

var is_shaping := false
var is_dragging := false

var is_operating :bool :
	get: return is_shaping or is_dragging


func _init(_silhouette :Silhouette):
	silhouette = _silhouette
	silhouette.applied.connect(_on_applied)
	silhouette.canceled.connect(_on_canceled)
	# use signal to separate different shaper is current using.
	# because shaper do not have _input event.
	# but silhouette can emit signal when key event is triggered.
	# then current shaper can tell sillhouette what to do. 


func reset():
	points.clear()
	is_shaping = false
	is_dragging = false
	silhouette.reset()


func shape_start(pos :Vector2i):
	if silhouette.has_point(pos):
		is_dragging = true
		silhouette.get_offset(pos)
	else:
		reset()  # must reset here because silhouette not working a image.
		is_shaping = true
		points.append(pos)


func shape_move(pos :Vector2i):
	if not is_shaping:
		shape_start(pos)


func shape_end(_pos :Vector2i):
	is_shaping = false
	is_dragging = false
	moving_offset = Vector2i.ZERO


#func move_to(to_pos :Vector2i, use_pivot := true):
#	silhouette.move_to(to_pos, use_pivot)
#
#
#func resize_to(to_size:Vector2i):
#	silhouette.resize_to(to_size)


func apply():
	silhouette.reset()
	reset()


func cancel():
	reset()
	silhouette.reset()



func _on_applied(_rect):
	if is_shaping:
		apply()


func _on_canceled():
	if is_shaping:
		cancel()
