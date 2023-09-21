extends SubViewportContainer

class_name Artboard

signal cursor_visible(state)


enum StateType {
	NONE,
	DRAG,
	ZOOM,
}

var project :Project

var state := StateType.NONE :
	set = activate_state



@onready var viewport :SubViewport = $Viewport
@onready var camera :Camera2D = $Viewport/Camera
@onready var canvas :Node2D = $Viewport/Canvas
@onready var transChecker :ColorRect = $Viewport/TransChecker


func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
#	print(g.current_project)
#	material = CanvasItemMaterial.new()
#	material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	
#	camera.zoom_100(g.current_project.size)
#	camera.camera_zoom_changed.connect(_on_camera_zoom_changed)
#	camera.camera_offset_changed.connect(_on_camera_offset_changed)
#
#	gui_input.connect(_on_gui_input)
#
#	transChecker.update_rect()
#	update_trans_checker_offset()
	pass


func load_project(proj :Project):
	project = proj

#	material = CanvasItemMaterial.new()
#	material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	
	camera.viewport_size = viewport.size
	camera.zoom_100()

#	camera.camera_offset_changed.connect(_on_camera_offset_changed)
	
	canvas.set_canvas_size(project.size)
	transChecker.update_rect(project.size)
	
	gui_input.connect(_on_gui_input)


func activate_state(op_state):
	# turn off old state
	match state:
		StateType.DRAG:
			camera.dragging = false
		StateType.ZOOM:
			camera.zooming = false
	
	# trun on new state	
	match op_state:
		StateType.DRAG:
			camera.dragging = true
		StateType.ZOOM:
			camera.zooming = true
			
	state = op_state


func update_canvas():
	canvas.queue_redraw()


#func save_to_project():
#	g.current_project.cameras_zoom = camera.zoom
#	g.current_project.cameras_offset = camera.offset
	

func _on_mouse_entered():
	camera.set_process_input(true)
	cursor_visible.emit(true)


func _on_mouse_exited():
	camera.set_process_input(false)
	cursor_visible.emit(false)


func _on_gui_input(event):
	if event is InputEventMouseMotion:
		camera.zoom_pos = get_local_mouse_position()
	

#func _on_camera_offset_changed(offset_val :float):
#	update_trans_checker_offset()
#	save_to_project()
#
#
#func _on_camera_zoom_changed(zoom_val :Vector2):
#	canvas.update_zoom(zoom_val)
#	update_trans_checker_offset()
#	save_to_project()



func _on_camera_changed(zoom_val, _origin_val, _scale_val):
	if canvas:
		canvas.camera_zoom = zoom_val
