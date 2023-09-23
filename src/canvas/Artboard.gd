extends SubViewportContainer

class_name Artboard


enum StateType {
	NONE,
	DRAG,
	ZOOM,
}

var project :Project

var state := StateType.NONE :
	set = activate_state

var guides :Array[Guide] = []

var symmetry_guide_h := SymmetryGuide.new()
var symmetry_guide_v := SymmetryGuide.new()
var symmetry_visible := false :
	set(val):
		symmetry_visible = val
		if symmetry_visible:
			symmetry_guide_h.show()
			symmetry_guide_v.show()
		else:
			symmetry_guide_h.hide()
			symmetry_guide_v.hide()

@onready var viewport :SubViewport = $Viewport
@onready var camera :Camera2D = $Viewport/Camera
@onready var canvas :Node2D = $Viewport/Canvas
@onready var transChecker :ColorRect = $Viewport/TransChecker

@onready var h_ruler :Button = $HRuler
@onready var v_ruler :Button = $VRuler


func _ready():
	add_child(symmetry_guide_h)
	add_child(symmetry_guide_v)
	symmetry_visible = true
	
	h_ruler.guide_created.connect(_on_guide_created)
	v_ruler.guide_created.connect(_on_guide_created)
	h_ruler.show()
	v_ruler.show()
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	resized.connect(_on_resized)
	camera.changed.connect(_on_resized)


func load_project(proj :Project):
	project = proj

#	material = CanvasItemMaterial.new()
#	material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	camera.canvas_size = project.size
	camera.viewport_size = viewport.size
	camera.zoom_100()
	
#	camera.camera_offset_changed.connect(_on_camera_offset_changed)
	canvas.subscribe(project)
	transChecker.update_rect(project.size)



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


func _on_mouse_exited():
	camera.set_process_input(false)


func place_symmetry_guide():
	if symmetry_visible and project:
		var _offset = camera.offset
		var _zoom = camera.zoom
		var _origin = Vector2(size * 0.5 - _offset * _zoom)  # to get origin
#		var _origin = camera.canvas_origin 
		# the origin in side the canvas is useless while on reised.
		var _x = _origin.x + project.size.x * 0.5 * _zoom.x
		var _y = _origin.y + project.size.y * 0.5 * _zoom.y
		symmetry_guide_h.set_guide(Vector2(-size.x, _y), Vector2(size.x, _y))
		symmetry_guide_v.set_guide(Vector2(_x, -size.y), Vector2(_x, size.y))


func place_rulers():
	h_ruler.set_ruler(size, project.size, camera.offset, camera.zoom)
	v_ruler.set_ruler(size, project.size, camera.offset, camera.zoom)


func place_guides():
	var _zoom = camera.zoom
	var _offset = camera.offset
	var _origin = Vector2(size * 0.5 - _offset * _zoom)  # to get origin
	for guide in guides:
		match guide.orientation:
			HORIZONTAL:
				var _y = guide.relative_position.y * _zoom.y
				guide.position.y = _origin.y - _y
			VERTICAL:
				var _x = guide.relative_position.x * _zoom.x
				guide.position.x = _origin.x - _x


func _on_resized(): 
	place_rulers()
	place_guides()
	place_symmetry_guide()


# guides

func _on_guide_created(type):
	var guide = Guide.new()
	guide.set_guide(type, size)
	guides.append(guide)
	add_child(guide)
	guide.pressed.connect(_on_guide_pressed)
	guide.released.connect(_on_guide_released)
	guide.hovered.connect(_on_guide_hovered)
	guide.leaved.connect(_on_guide_leaved)
	

func _on_guide_hovered(guide):
	for _guide in guides:
		if _guide != guide:
			_guide.is_hovered = false
	match guide.orientation:
		HORIZONTAL:
			mouse_default_cursor_shape = Control.CURSOR_VSPLIT
		VERTICAL:
			mouse_default_cursor_shape = Control.CURSOR_HSPLIT


func _on_guide_leaved(_guide):
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_guide_pressed(guide):
	# clear up other guide status
	for _guide in guides:
		if _guide != guide:
			_guide.is_pressed = false


func _on_guide_released(guide):
	var _offset = camera.offset
	var _zoom = camera.zoom
	var _origin = Vector2(size * 0.5 - _offset * _zoom) # to get origin
	
	guide.relative_position = (_origin - guide.position) / _zoom
	# calculate to the right position when zoom is 1.0.
	# otherwise position might mess-up place guide while is zoomed.
	
	match guide.orientation:
		HORIZONTAL:
			if guide.position.y < h_ruler.size.y:
				guide.pressed.disconnect(_on_guide_pressed)
				guide.released.disconnect(_on_guide_released)
				guides.erase(guide)
				guide.queue_free()
				mouse_default_cursor_shape = Control.CURSOR_ARROW
		VERTICAL:
			if guide.position.x < v_ruler.size.x:
				guide.pressed.disconnect(_on_guide_pressed)
				guide.released.disconnect(_on_guide_released)
				guides.erase(guide)
				guide.queue_free()
				mouse_default_cursor_shape = Control.CURSOR_ARROW
