class_name Artboard extends SubViewportContainer

enum {
	NONE,
	MOVE,
	DRAG,
	ZOOM,
	PENCIL,
	BRUSH,
	ERASE,
	CROP,
	SELECT_RECTANGLE,
	SELECT_ELLIPSE,
	SELECT_POLYGON,
	SELECT_LASSO,
}

var state := Artboard.NONE :
	set(val):
		state = val
		canvas.state = state
		camera.state = state
		change_state_cursor(state)
#		if state == Artboard.MOVE:
#			_lock_guides(guides_locked)
#		else:
#			_lock_guides(true)

var project :Project

var selected_rect :Rect2i:
	get: return canvas.selected_rect

var camera_offset :Vector2 :
	get: return camera.offset
	
var camera_zoom :Vector2 :
	get: return camera.zoom
	
var camera_origin :Vector2 :
	get: return Vector2(size * 0.5 - camera_offset * camera_zoom)

var reference_image := ReferenceImage.new()

var guides :Array[Guide] = []
var guides_locked := false :
	set(val):
		guides_locked = val
#		_lock_guides(guides_locked or state != Artboard.MOVE)
		_lock_guides(guides_locked)
		
var show_guides := false :
	set(val):
		show_guides = val
		for guide in guides:
			guide.visible = show_guides
		v_ruler.set_activate(show_guides)
		h_ruler.set_activate(show_guides)
		place_guides()

var show_grid_state := Grid.NONE :
	set(val):
		show_grid_state = val
		grid.state = show_grid_state
		place_grid()

var show_symmetry_guide_state := SymmetryGuide.NONE :
	set(val):
		show_symmetry_guide_state = val
		symmetry_guide.state = show_symmetry_guide_state
		symmetry_guide.set_guide(size)
		place_symmetry_guides()

var show_mouse_guide := false:
	set(val):
		show_mouse_guide = val
		mouse_guide.visible = val
		mouse_guide.set_guide(size)

var show_rulers := false:
	set(val):
		show_rulers = val
		h_ruler.visible = val
		v_ruler.visible = val
		place_rulers()

var snap_to_guide :bool:
	set(val):
		canvas.snap_to_guide = val
	get: return canvas.snap_to_guide

var snap_to_grid_center :bool:
	set(val):
		canvas.snap_to_grid_center = val
	get: return canvas.snap_to_grid_center

var snap_to_grid_boundary :bool :
	set(val):
		canvas.snap_to_grid_boundary = val
	get: return canvas.snap_to_grid_boundary

var snap_to_symmetry_guide :bool :
	set(val):
		canvas.snap_to_symmetry_guide = val
	get: return canvas.snap_to_symmetry_guide

@onready var viewport :SubViewport = $Viewport
@onready var camera :Camera2D = $Viewport/Camera
@onready var canvas :Node2D = $Viewport/Canvas
@onready var trans_checker :ColorRect = $Viewport/TransChecker

@onready var h_ruler :Button = $HRuler
@onready var v_ruler :Button = $VRuler

@onready var symmetry_guide :Node2D = $SymmetryGuide
@onready var mouse_guide :Node2D = $MouseGuide
@onready var grid :Node2D = $Viewport/Grid


func _ready():
	h_ruler.guide_created.connect(_on_guide_created)
	v_ruler.guide_created.connect(_on_guide_created)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	resized.connect(_on_artboard_resized)
	camera.dragged.connect(_on_camera_changed)
	camera.zoomed.connect(_on_camera_changed)
	camera.press_changed.connect(_on_camera_pressing)
	
	canvas.cursor_changed.connect(_on_canvas_change_cursor)
	canvas.operating.connect(_on_canvas_operating)
	canvas.crop_canvas.connect(_on_canvas_cropping)
	
	trans_checker.add_sibling(reference_image)
	
	mouse_guide.set_guide(size)
	symmetry_guide.set_guide(size)
	
	state = Artboard.NONE  # trggier options when state changed.


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
	canvas.attach_snap_to(project.size, guides, symmetry_guide, grid)
	trans_checker.update_bounds(project.size)
	

func crop_project(rect):
	print(rect)


func save_to_project():
	pass


func refresh_canvas():
	canvas.queue_redraw()


func change_state_cursor(curr_state):
	if curr_state == Artboard.MOVE:
		mouse_default_cursor_shape = Control.CURSOR_MOVE
	elif curr_state == Artboard.DRAG: 
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	elif curr_state in [Artboard.BRUSH, Artboard.PENCIL, Artboard.ERASE]:
		mouse_default_cursor_shape = Control.CURSOR_CROSS
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW


func place_grid():
	if project and show_grid_state != Grid.NONE:
		grid.zoom_at = camera.zoom.x


func place_symmetry_guides():
	if project and show_symmetry_guide_state != SymmetryGuide.NONE:
		symmetry_guide.move(project.size, camera_origin, camera_zoom)


func place_rulers():
	if project and show_rulers:
		h_ruler.set_ruler(size, project.size, camera_offset, camera_zoom)
		v_ruler.set_ruler(size, project.size, camera_offset, camera_zoom)


func place_guides():
	if project and show_guides:
		for guide in guides:
			match guide.orientation:
				HORIZONTAL:
					guide.position.y = camera_origin.y + \
						guide.relative_position.y * camera_zoom.y
				VERTICAL:
					guide.position.x = camera_origin.x + \
						guide.relative_position.x * camera_zoom.x


func _on_artboard_resized():
	_on_camera_changed() # do samething with camera changed.
	
	# no need to sheck show options, hiden will still be hidden,
	# but keep the size correct, even it is not showing up.
	
	mouse_guide.resize(size) 
	symmetry_guide.resize(size)
	
	for guide in guides:
		guide.resize(size)


func _on_camera_changed():
	place_rulers()
	place_guides()
	place_symmetry_guides()
	place_grid()
	canvas.zoom = camera_zoom
	

func _on_camera_pressing(is_pressed):
	if state == Artboard.DRAG:
		if is_pressed:
			mouse_default_cursor_shape = Control.CURSOR_DRAG
		else:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_canvas_operating(_state:int, _operator :Variant, is_finished :bool):
	if is_finished:
		_lock_guides(guides_locked)
	else:
		_lock_guides(true)


func _on_canvas_cropping(rect):
	crop_project(rect)


func _on_canvas_change_cursor(cursor):
	if cursor:
		mouse_default_cursor_shape = cursor
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_mouse_entered():
	camera.set_process_input(true)


func _on_mouse_exited():
	camera.set_process_input(false)


# guides
func _lock_guides(val :bool): # do not use it in other scopes.
	# for internal use, temporary lock guides while state switched.
	for guide in guides:
		guide.is_locked = val


func _on_guide_created(type):
	var guide = Guide.new()
	guide.set_guide(type, size)
	guides.append(guide)
	add_child(guide)
	guide.get_artboard_mouse_position = func():
		# for make sure position is from artboard when guide is dragging.
		return get_local_mouse_position()
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
	if not guide.is_locked:
		canvas.frozen = true  # frozen canvas if guide is not locked.


func _on_guide_leaved(_guide):
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	canvas.frozen = false  # unfrozen canvas anyway.


func _on_guide_pressed(guide):
	# clear up other guide status
	for _guide in guides:
		if _guide != guide:
			_guide.is_pressed = false


func _on_guide_released(guide):
#	guide.is_locked = guides_locked or state != Artboard.MOVE
	guide.is_locked = guides_locked
	
	guide.relative_position = canvas.get_relative_mouse_position()
	# take canvas local mouse position as rounded.
	# calculate to the relative position might not working precisely.
	# otherwise position might mess-up place guide while is zoomed and snapping.
	match guide.orientation:
		HORIZONTAL:
			if guide.position.y < h_ruler.size.y:
				guide.pressed.disconnect(_on_guide_pressed)
				guide.released.disconnect(_on_guide_released)
				guides.erase(guide)
				guide.queue_free()
				mouse_default_cursor_shape = Control.CURSOR_ARROW
			elif selected_rect.size != Vector2i.ZERO:
				guide.snap_to(selected_rect.position)
				guide.snap_to(selected_rect.position + selected_rect.size)
		VERTICAL:
			if guide.position.x < v_ruler.size.x:
				guide.pressed.disconnect(_on_guide_pressed)
				guide.released.disconnect(_on_guide_released)
				guides.erase(guide)
				guide.queue_free()
				mouse_default_cursor_shape = Control.CURSOR_ARROW
			elif selected_rect.size != Vector2i.ZERO:
				guide.snap_to(selected_rect.position)
				guide.snap_to(selected_rect.position + selected_rect.size)
	
	# make sure guides is in place
	place_guides()
