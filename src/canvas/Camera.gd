extends Camera2D

class_name CameraMovement

signal changed(zoom_val, origin_val, scale_val)

const CAMERA_SPEED_RATE = 12.0

var viewport_size := Vector2.ZERO

var zoom_in_max := Vector2(500, 500)
var zoom_out_max := Vector2(0.01, 0.01)

var zoom_pos := Vector2.ZERO
var dragging := false
var zooming := false
var btn_pressed := false

func _ready():
	set_process_input(false)
	send_camera_changed()


func _input(event: InputEvent):
	if event is InputEventMouseButton:
		btn_pressed = event.pressed
	
	if event is InputEventMagnifyGesture:  # Zoom Gesture on a laptop touchpad
		if event.factor < 1:
			zoom_camera(1)
		else:
			zoom_camera(-1)
	elif event is InputEventPanGesture and OS.get_name() != "Android":
		# Pan Gesture on a laptop touchpad
		offset = offset + event.delta * 7.0 / zoom
		send_camera_changed()
	
	# hit the hot key directly.
	elif event.is_action_pressed("zoom_in"):
		zoom_camera(1)
	elif event.is_action_released("zoom_out"):
		zoom_camera(-1)
	
	# activated by pan tool.
	elif dragging and event is InputEventMouseMotion and btn_pressed:
		offset = offset - event.relative / zoom
		send_camera_changed()
	
	# activated by zoom tool, with mouse click to zoom in and out.
	elif zooming and event is InputEventMouseButton and btn_pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			zoom_camera(1)
		else:
			zoom_camera(-1)


func zoom_camera(direction: int):
	var new_zoom := zoom + (zoom * direction / 6)
	if zoom >= Vector2.ONE and direction > 0:
		new_zoom = (zoom + Vector2.ONE * direction).floor()
	if new_zoom < zoom_in_max && new_zoom > zoom_out_max:
		var new_offset = (
			offset + (
				(-0.5 * viewport_size + zoom_pos)
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
	offset = viewport_size / 2
	send_camera_changed()
	

func fit_to_frame(size: Vector2) -> void:
	offset = size / 2
	var h_ratio = viewport_size.x / size.x
	var v_ratio = viewport_size.y / size.y
	var ratio = minf(h_ratio, v_ratio)
	if ratio == 0 or not visible:
		ratio = 0.1  # Set it to a non-zero value just in case

	ratio = clampf(ratio, 0.1, ratio)
	zoom = Vector2(ratio, ratio)
	send_camera_changed()


func _on_zoom_step(_idx: int):
	send_camera_changed()


func send_camera_changed():
	var o := get_global_transform_with_canvas().get_origin()
	var s := get_global_transform_with_canvas().get_scale()
	o.y = get_viewport_rect().size.y - o.y
	changed.emit(zoom, o, s)
