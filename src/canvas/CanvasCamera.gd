extends Camera2D

class_name CanvasCamera

signal zoomed
signal dragged
signal change_pressed

const CAMERA_SPEED_RATE = 12.0

var viewport_size := Vector2i.ZERO
var canvas_size := Vector2i.ZERO :
	set(val):
		canvas_size = val
		limit_left = val.x * -100
		limit_top = val.y * -100
		limit_right = val.x * 100
		limit_bottom = val.y * 100
		# limit will effect zoom out
		# when zoom out to very small size, might touch the limit.
		# that will cause the canvas MOVE AWAY.
		# so do not make it too small. 
		# make the zoom_out_max (or zoom_in_max)
		# fit the limit size will be nice.
		
var zoom_in_max := Vector2(100, 100)
var zoom_out_max := Vector2(0.1, 0.1)
var zoom_center_point := Vector2.ZERO

var canvas_origin := Vector2.ZERO
var canvas_scale := Vector2.ZERO

var use_integer_zoom := false

var btn_pressed := false
var state := Artboard.NONE


func _ready():
	set_process_input(false)


func _input(event: InputEvent):
	if event is InputEventMagnifyGesture:  # Zoom Gesture on a laptop touchpad
		if event.factor < 1:
			zoom_camera(1)
		else:
			zoom_camera(-1)
		send_camera_zoomed()
	elif event is InputEventPanGesture and OS.get_name() != "Android":
		# Pan Gesture on a laptop touchpad
		offset = offset + event.delta * 7.0 / zoom
		send_camera_dragged()
	
	# hit the hot key directly.
	elif event.is_action_pressed("zoom_in"):
		zoom_center_point = canvas_size * 0.5 
		zoom_camera(1)
		send_camera_zoomed()
	elif event.is_action_released("zoom_out"):
		zoom_center_point = canvas_size * 0.5
		zoom_camera(-1)
		send_camera_zoomed()
	
	if event is InputEventMouseButton:
		btn_pressed = event.pressed
		change_pressed.emit(btn_pressed)
		
	match state:
		Artboard.DRAG:
			process_dragging(event)
			send_camera_dragged()
		Artboard.ZOOM:
			process_zooming(event)
			send_camera_zoomed()


func process_dragging(event):
	# activated by pan tool.
	if event is InputEventMouseMotion and btn_pressed:
		offset = offset - event.relative / zoom


func process_zooming(event):
	# activated by zoom tool, with mouse click to zoom in and out.
	if event is InputEventMouseButton and btn_pressed:
		if (event.button_index == MOUSE_BUTTON_LEFT or 
			event.button_index == MOUSE_BUTTON_WHEEL_UP):
			zoom_center_point = get_local_mouse_position()
			zoom_camera(1)
		elif (event.button_index == MOUSE_BUTTON_RIGHT or 
			  event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			zoom_center_point = get_local_mouse_position()
			zoom_camera(-1)	


func zoom_camera(direction: int):
	var new_zoom := zoom + (zoom * direction / 5)
#	if use_integer_zoom:
#		new_zoom = (zoom + Vector2.ONE * direction).floor()
	if new_zoom < zoom_in_max && new_zoom > zoom_out_max:
		zoom = new_zoom
		offset = zoom_center_point
		send_camera_zoomed()
		
		# use Tween to smooth the zoom effect. DO NEED for now.
#		var tween = create_tween().set_parallel()
#		tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
#		tween.step_finished.connect(_on_zoom_step_finished)
#		tween.tween_property(self, "zoom", new_zoom, 0.05)
#		tween.tween_property(self, "offset", zoom_center_point, 0.05)


func zoom_100():
	zoom = Vector2.ONE
	zoom_center_point = canvas_size * 0.5
	offset = zoom_center_point
	send_camera_zoomed()
	

func fit_to_frame() -> void:
	offset = canvas_size / 2
	var h_ratio = viewport_size.x / float(canvas_size.x)
	var v_ratio = viewport_size.y / float(canvas_size.y)
	var ratio = minf(h_ratio, v_ratio)
	if ratio == 0 or not visible:
		ratio = 0.1  # Set it to a non-zero value just in case

	ratio = clampf(ratio, 0.1, ratio)
	zoom = Vector2(ratio, ratio)
	send_camera_zoomed()


func send_camera_zoomed():
	canvas_origin = get_global_transform_with_canvas().get_origin()
	canvas_scale = get_global_transform_with_canvas().get_scale()
	zoomed.emit()


func send_camera_dragged():
	canvas_origin = get_global_transform_with_canvas().get_origin()
	canvas_scale = get_global_transform_with_canvas().get_scale()
	dragged.emit()
