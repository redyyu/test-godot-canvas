extends Camera2D

class_name CameraMovement

signal changed()

const CAMERA_SPEED_RATE = 12.0

var viewport_size := Vector2i.ZERO
var canvas_size := Vector2i.ZERO

var zoom_in_max := Vector2(500, 500)
var zoom_out_max := Vector2(0.01, 0.01)
var zoom_center_point := Vector2.ZERO

var canvas_origin := Vector2.ZERO
var canvas_scale := Vector2.ZERO

var use_integer_zoom := false
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
		zoom_center_point = canvas_size * 0.5 
		zoom_camera(1)
	elif event.is_action_released("zoom_out"):
		zoom_center_point = canvas_size * 0.5
		zoom_camera(-1)
	
	# activated by pan tool.
	elif dragging and event is InputEventMouseMotion and btn_pressed:
		offset = offset - event.relative / zoom
		send_camera_changed()
	
	# activated by zoom tool, with mouse click to zoom in and out.
	elif zooming and event is InputEventMouseButton and btn_pressed:
		if (event.button_index == MOUSE_BUTTON_LEFT or 
			event.button_index == MOUSE_BUTTON_WHEEL_UP):
			zoom_center_point = get_local_mouse_position()
			zoom_camera(1)
		elif (event.button_index == MOUSE_BUTTON_RIGHT or 
			  event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			zoom_center_point = get_local_mouse_position()
			zoom_camera(-1)


func zoom_camera(direction: int):
	var new_zoom := zoom + (zoom * direction / 10)
	if use_integer_zoom:
		new_zoom = (zoom + Vector2.ONE * direction).floor()
	if new_zoom < zoom_in_max && new_zoom > zoom_out_max:
		zoom = new_zoom
		offset = zoom_center_point
		send_camera_changed()
#		var tween = create_tween().set_parallel()
#		tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
#		tween.step_finished.connect(_on_zoom_step_finished)
#		tween.tween_property(self, "zoom", new_zoom, 0.05)
#		tween.tween_property(self, "offset", zoom_center_point, 0.05)


func zoom_100():
	zoom = Vector2.ONE
	zoom_center_point = canvas_size * 0.5
	offset = zoom_center_point
	send_camera_changed()
	

func fit_to_frame() -> void:
	offset = canvas_size / 2
	var h_ratio = viewport_size.x / float(canvas_size.x)
	var v_ratio = viewport_size.y / float(canvas_size.y)
	var ratio = minf(h_ratio, v_ratio)
	if ratio == 0 or not visible:
		ratio = 0.1  # Set it to a non-zero value just in case

	ratio = clampf(ratio, 0.1, ratio)
	zoom = Vector2(ratio, ratio)
	send_camera_changed()


func send_camera_changed():
	canvas_origin = get_global_transform_with_canvas().get_origin()
	canvas_scale = get_global_transform_with_canvas().get_scale()
	changed.emit()
