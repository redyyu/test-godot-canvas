extends SubViewportContainer

class_name Artboard


var state := ArtboardState.NONE :
	set = set_state

var project :Project

var reference_image := ReferenceImage.new()

var guides_locked := false
var guides :Array[Guide] = []
var grid := Grid.new()

var symmetry_guide_h := SymmetryGuide.new()
var symmetry_guide_v := SymmetryGuide.new()
var symmetry_guide_state := SymmetryGuide.NONE :
	set = set_symmetry_guides

@onready var viewport :SubViewport = $Viewport
@onready var camera :Camera2D = $Viewport/Camera
@onready var canvas :Node2D = $Viewport/Canvas
@onready var trans_checker :ColorRect = $Viewport/TransChecker

@onready var h_ruler :Button = $HRuler
@onready var v_ruler :Button = $VRuler
@onready var mouse_guide :Node2D = $MouseGuide


func _ready():
	add_child(symmetry_guide_h)
	add_child(symmetry_guide_v)
	
	h_ruler.guide_created.connect(_on_guide_created)
	v_ruler.guide_created.connect(_on_guide_created)
	h_ruler.show()
	v_ruler.show()
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	resized.connect(_on_viewport_changed)
	camera.dragged.connect(_on_viewport_changed)
	camera.zoomed.connect(_on_viewport_changed)
	camera.change_pressed.connect(_on_camera_pressing)
	
	trans_checker.add_sibling(reference_image)
	viewport.add_child(grid)
	
	set_state(ArtboardState.NONE)


func load_project(proj :Project):
	project = proj
	
	reference_image.canvas_size = project.size
	grid.canvas_size = project.size
	
#	material = CanvasItemMaterial.new()
#	material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	camera.canvas_size = project.size
	camera.viewport_size = viewport.size
	camera.zoom_100()
	
#	camera.camera_offset_changed.connect(_on_camera_offset_changed)
	canvas.attach_project(project)
	canvas.attach_snap_to(project.size, guides, grid)
	trans_checker.update_bounds(project.size)
	
	mouse_guide.set_mouse_guide(size)
	

func save_to_project():
	pass


func set_state(op_state):
	state = op_state
	canvas.state = state
	camera.state = state
	
	if state == ArtboardState.MOVE:
		_lock_guides(guides_locked)
	else:
		_lock_guides(true)
		
	change_cursor(state)
		

func refresh_canvas():
	canvas.queue_redraw()


func change_cursor(curr_state):
	match curr_state:
		ArtboardState.MOVE:
			mouse_default_cursor_shape = Control.CURSOR_MOVE
		ArtboardState.DRAG:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		ArtboardState.BRUSH:
			mouse_default_cursor_shape = Control.CURSOR_CROSS
		ArtboardState.PENCIL:
			mouse_default_cursor_shape = Control.CURSOR_CROSS
		ArtboardState.ERASE:
			mouse_default_cursor_shape = Control.CURSOR_CROSS
		_:
			mouse_default_cursor_shape = Control.CURSOR_ARROW


func place_grid():
	grid.zoom_at = camera.zoom.x


func set_symmetry_guides(val):
	symmetry_guide_state = val
	match symmetry_guide_state:
		SymmetryGuide.CROSS_AXIS:
			symmetry_guide_h.show()
			symmetry_guide_v.show()
		SymmetryGuide.HORIZONTAL_AXIS:
			symmetry_guide_h.show()
			symmetry_guide_v.hide()
		SymmetryGuide.VERTICAL_AXIS:
			symmetry_guide_h.hide()
			symmetry_guide_v.show()
		_:
			symmetry_guide_h.hide()
			symmetry_guide_v.hide()
	place_symmetry_guide()


func place_symmetry_guide():
	if project:
		var _offset = camera.offset
		var _zoom = camera.zoom
		var _origin = Vector2(size * 0.5 - _offset * _zoom)  # to get origin
			
		match symmetry_guide_state:
			SymmetryGuide.HORIZONTAL_AXIS:
				_set_horizontal_symmetry_guide(_origin, project.size, _zoom)
			SymmetryGuide.VERTICAL_AXIS:
				_set_vertical_symmetry_guide(_origin, project.size, _zoom)
			SymmetryGuide.CROSS_AXIS:
				_set_horizontal_symmetry_guide(_origin, project.size, _zoom)
				_set_vertical_symmetry_guide(_origin, project.size, _zoom)
			_:
				symmetry_guide_h.hide()
				symmetry_guide_v.hide()


func _set_horizontal_symmetry_guide(origin, canvas_size, zoom):
	var _y = origin.y + canvas_size.y * 0.5 * zoom.y
	symmetry_guide_h.set_guide(Vector2(-size.x, _y), Vector2(size.x, _y))


func _set_vertical_symmetry_guide(origin, canvas_size, zoom):
	var _x = origin.x + canvas_size.x * 0.5 * zoom.x
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
				var _y = guide.relative_offset.y * _zoom.y
				guide.position.y = _origin.y + _y
			VERTICAL:
				var _x = guide.relative_offset.x * _zoom.x
				guide.position.x = _origin.x + _x 


func _on_viewport_changed():
	place_rulers()
	place_guides()
	place_symmetry_guide()
	place_grid()
	

func _on_camera_pressing(is_pressed):
	if state == ArtboardState.DRAG:
		if is_pressed:
			mouse_default_cursor_shape = Control.CURSOR_DRAG
		else:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		


func _on_mouse_entered():
	camera.set_process_input(true)


func _on_mouse_exited():
	camera.set_process_input(false)


# guides

func lock_guides(val :bool):
	guides_locked = bool(val)
	_lock_guides(guides_locked or state != ArtboardState.MOVE)
	

func _lock_guides(val :bool):
	# for internal use, temporary lock guides while state switched.
	for guide in guides:
		guide.is_locked = val
		
	v_ruler.set_activate(not val)
	h_ruler.set_activate(not val)


func _on_guide_created(type):
	if (not guides_locked and state == ArtboardState.MOVE):
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
	
	guide.relative_offset = (guide.position - _origin) / _zoom
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
