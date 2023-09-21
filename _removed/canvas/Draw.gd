extends SubViewportContainer

signal cursor_visible(state)

@onready var camera :Camera2D = $DrawViewport/Camera
@onready var canvas :Node2D = $DrawViewport/Canvas
@onready var transChecker :Node2D = $DrawViewport/TransChecker
@onready var viewport :SubViewport = $DrawViewport


func _ready():
	material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	
	camera.zoom_100(g.current_project.size)
	camera.camera_zoom_changed.connect(_on_camera_zoom_changed)
	camera.camera_offset_changed.connect(_on_camera_offset_changed)
	
	gui_input.connect(_on_gui_input)
	
	transChecker.update_rect()
	update_trans_checker_offset()
	

func update_canvas():
	canvas.queue_redraw()


func update_trans_checker_offset():
	var o := get_global_transform_with_canvas().get_origin()
	var s := get_global_transform_with_canvas().get_scale()
	o.y = get_viewport_rect().size.y - o.y
	transChecker.update_offset(o, s)
	

func save_to_project():
	g.current_project.cameras_zoom = camera.zoom
	g.current_project.cameras_offset = camera.offset
	

func _on_mouse_entered():
	camera.set_process_input(true)
	g.has_focus = true
	cursor_visible.emit(true)


func _on_mouse_exited():
	camera.set_process_input(false)
	g.has_focus = false
	cursor_visible.emit(false)


func _on_gui_input(event):
	if event is InputEventMouseMotion:
		var mouse_pos = viewport.get_local_mouse_position()
		camera.mouse_pos = mouse_pos
		canvas.mouse_pos = mouse_pos
		canvas.camera_zoom = camera.zoom


func _on_camera_offset_changed(offset_val :float):
	update_trans_checker_offset()
	save_to_project()
	

func _on_camera_zoom_changed(zoom_val :Vector2):
	canvas.update_zoom(zoom_val)
	update_trans_checker_offset()
	save_to_project()
