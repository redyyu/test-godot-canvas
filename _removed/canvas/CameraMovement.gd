extends Camera2D

class_name CameraMovement

signal camera_zoom_changed(zoom_val)
signal camera_offset_changed(offset_val)

const CAMERA_SPEED_RATE = 15.0

var zoom_in_max :Vector2 = Vector2(500, 500)
var zoom_out_max :Vector2 = Vector2(0.01, 0.01)
var viewport_size :Vector2 = Vector2.ZERO
var mouse_pos :Vector2 = Vector2.ZERO
var drag :bool = false
var should_tween :bool = true


func _ready():
	set_process_input(false)


func _input(event: InputEvent):
	if !g.can_draw:
		drag = false
		return
	if event.is_action_pressed("pan"):
		drag = true
	elif event.is_action_released("pan"):
		drag = false
	elif event.is_action_pressed("zoom_in", false, true):  # Wheel Up Event
		zoom_camera(1)
	elif event.is_action_pressed("zoom_out", false, true):  # Wheel Down Event
		zoom_camera(-1)
	elif event is InputEventMagnifyGesture:  # Zoom Gesture on a laptop touchpad
		if event.factor < 1:
			zoom_camera(1)
		else:
			zoom_camera(-1)
	elif event is InputEventPanGesture and OS.get_name() != "Android":
		# Pan Gesture on a laptop touchpad
		offset = offset + event.delta.rotated(rotation) * 7.0 / zoom
		camera_offset_changed.emit(offset)
	elif event is InputEventMouseMotion:
		if drag:
			offset = offset - event.relative.rotated(rotation) / zoom
			camera_offset_changed.emit(offset)


func zoom_camera(direction: int):
	var new_zoom = (zoom + Vector2.ONE * direction).floor()
	if new_zoom < zoom_in_max && new_zoom > zoom_out_max:
		var new_offset = (
			offset + (
				(-0.5 * viewport_size + mouse_pos)
				* (Vector2.ONE / zoom - Vector2.ONE / new_zoom)
			)
		)
		var tween = create_tween().set_parallel()
		tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		tween.step_finished.connect(_on_zoom_step)
		tween.tween_property(self, "zoom", new_zoom, 0.05)
		tween.tween_property(self, "offset", new_offset, 0.05)	


func zoom_100():
	zoom = Vector2.ONE
	offset = g.current_project.size / 2
	camera_zoom_changed.emit(zoom)
	

func fit_to_frame(size: Vector2) -> void:
	offset = size / 2
	var h_ratio = viewport_size.x / size.x
	var v_ratio = viewport_size.y / size.y
	var ratio = minf(h_ratio, v_ratio)
	if ratio == 0 or not visible:
		ratio = 0.1  # Set it to a non-zero value just in case

	ratio = clampf(ratio, 0.1, ratio)
	zoom = Vector2(ratio, ratio)
	camera_zoom_changed.emit(zoom)


func _on_zoom_step(_idx: int):
	should_tween = false
	camera_zoom_changed.emit(zoom)
	for guide in g.current_project.guides:
		guide.width = 1.0 / zoom.x * 2
	should_tween = true
	
