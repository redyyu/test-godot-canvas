class_name Canvas extends Node2D

signal cursor_updated(cursor)
signal selection_updated(rect)
signal crop_applied(rect)

signal operating(operate_state, is_finished)
# let parent to know when should block some other actions.
# for improve useblilty.


var state := Artboard.NONE:
	set = set_state

var pencil := PencilDrawer.new()
var brush := BrushDrawer.new()
var eraser := EraseDrawer.new()

var rect_selector := RectSelector.new()
var ellipse_selector := EllipseSelector.new()
var polygon_selector := PolygonSelector.new()
var lasso_selector := LassoSelector.new()
		
var project :Project
var size :Vector2i :
	get:
		if project:
			return project.size
		else:
			return Vector2i.ZERO

var selected_rect: Rect2i :
	get: return selection.selected_rect

const DEFAULT_PEN_PRESSURE := 1.0
const DEFAULT_PEN_VELOCITY := 1.0

var pressure_min_thres := 0.0
var pressure_max_thres := 1.0
var velocity_min_thres := 0.0
var velocity_max_thres := 1.0

var dynamics_stroke_width := Dynamics.NONE
var dynamics_stroke_alpha := Dynamics.NONE

var snapper := Snapper.new()

var is_pressed := false
var frozen := false # temporary prevent canvas operations. for parents mostlly.

var zoom := Vector2.ONE :
	set = set_zoom_ratio

@onready var indicator :Indicator = $Indicator
@onready var selection :Selection = $Selection
@onready var cropper :Cropper = $Cropper
@onready var mover :Mover = $Mover

#var mirror_view :bool = false
#var draw_pixel_grid :bool = false
#var grid_draw_over_tile_mode :bool = false
#var shape_perfect :bool = false
#var shape_center :bool = false

#var onion_skinning :bool = false
#var onion_skinning_past_rate := 1.0
#var onion_skinning_future_rate := 1.0

#@onready var tile_mode :Node2D = $TileMode
#@onready var pixel_grid :Node2D = $PixelGrid
#@onready var grid :Node2D = $Grid
#@onready var selection :Node2D = $Selection
#@onready var onion_past :Node2D = $OnionPast
#@onready var onion_future :Node2D = $OnionFuture
#@onready var cropper :Cropper = $Cropper


func _ready():
#	onion_past.type = onion_past.PAST
#	onion_past.blue_red_color = Color.RED
#	onion_future.type = onion_future.FUTURE
#	onion_future.blue_red_color = Color.BLUE
	
	# attach selection to selector
	rect_selector.selection = selection
	ellipse_selector.selection = selection
	polygon_selector.selection = selection
	lasso_selector.selection = selection
	selection.selected.connect(_on_selection_updated)
	
	pencil.mask = selection.mask
	brush.mask = selection.mask
	eraser.mask = selection.mask
	
	var snapper_weight_hook = func(pos) -> Vector3i:
		return snapper.snap_position_weight(pos, true)
	
	cropper.applied.connect(_on_crop_applied)
	cropper.cursor_updated.connect(_on_curosr_updated)
	cropper.inject_sizer_snapping(snapper_weight_hook)
	
	mover.updated.connect(_on_transformer_updated)
	mover.cursor_updated.connect(_on_curosr_updated)
	mover.inject_sizer_snapping(snapper_weight_hook)


func attach_project(proj):
	project = proj
	
	selection.size = project.size
	cropper.size = project.size
	
	set_state(state)  # trigger state changing to init settings.


func set_state(val):  # triggered when state changing.
	# allow change without really changed val, trigger funcs in setter.
	state = val
	is_pressed = false
	
	indicator.hide_indicator()  # not all state need indicator
	
	if state == Artboard.CROP:
		mover.cancel()
		cropper.launch()
		selection.deselect()
	elif state == Artboard.MOVE:
		cropper.cancel()
		mover.lanuch(project.current_cel.get_image(), 
						 		selection.mask)
		# selection must clear after transform setted, 
		# free_transform still need it once.
		selection.deselect() 
	elif state in [Artboard.BRUSH, Artboard.PENCIL, Artboard.ERASE]:
		mover.apply(true)
		cropper.cancel()
		pencil.attach(project.current_cel.get_image())
		brush.attach(project.current_cel.get_image())
		eraser.attach(project.current_cel.get_image())
		# DO NOT clear selection here, drawer can draw by selection.
	elif state not in [Artboard.DRAG, Artboard.ZOOM]:
		mover.apply(true)
		cropper.cancel()


func set_zoom_ratio(val):
	if zoom == val:
		return
	zoom = val
	var zoom_ratio = (zoom.x + zoom.y) / 2
	selection.zoom_ratio = zoom_ratio
	cropper.zoom_ratio = zoom_ratio
	mover.zoom_ratio = zoom_ratio


func prepare_pressure(pressure:float) -> float:
	if pressure == 0.0:
		# when the device pressure is not supported will always be 0.0
		# use it with button pressed check some where.
		return 1.0
	pressure = remap(pressure, pressure_min_thres, pressure_max_thres, 0.0, 1.0)
	pressure = clampf(pressure, 0.0, 1.0)
	return pressure


func prepare_velocity(mouse_velocity:Vector2i) -> float:
	# convert velocity to 0.0~1.0
	var velocity = mouse_velocity.length() / 1000.0 
	
	velocity = remap(velocity, velocity_min_thres, velocity_max_thres, 0.0, 1.0)
	velocity = clampf(velocity, 0.0, 1.0)
	return 1 - velocity  # more fast should be more week.


func process_drawing_or_erasing(event, drawer):
	if event is InputEventMouseMotion:
		var pos = snapper.snap_position(get_local_mouse_position())
		indicator.show_indicator(pos, drawer.stroke_dimensions)

		if (not drawer.can_draw(pos) or
			not project.current_cel is PixelCel):
			return
			
		if is_pressed:
			match dynamics_stroke_width:
				Dynamics.PRESSURE:
					drawer.set_stroke_width_dynamics(
						prepare_pressure(event.pressure))
				Dynamics.VELOCITY:
					drawer.set_stroke_width_dynamics(
						prepare_velocity(event.velocity))
				_:
					drawer.set_stroke_width_dynamics() # back to default
			match dynamics_stroke_alpha:
				Dynamics.PRESSURE:
					drawer.set_stroke_alpha_dynamics(
						prepare_pressure(event.pressure))
				Dynamics.VELOCITY:
					drawer.set_stroke_alpha_dynamics(
						prepare_velocity(event.velocity))
				_:
					drawer.set_stroke_alpha_dynamics() # back to default
			drawer.draw_move(pos)
			project.current_cel.update_texture()
			queue_redraw()
				
		elif drawer.is_drawing:
			drawer.draw_end(pos)
			project.current_cel.update_texture()
			queue_redraw()


func process_selection(event, selector):
	if event is InputEventMouseMotion:
		var pos = snapper.snap_position(get_local_mouse_position(), true)
		if is_pressed:
			selector.select_move(pos)
		elif selector.is_operating:
			selector.select_end(pos)


func process_selection_polygon(event, selector):
	if event is InputEventMouseButton:
		var pos = snapper.snap_position(get_local_mouse_position(), true)
		if is_pressed and not event.double_click:
			selector.select_move(pos)
		elif selector.is_selecting and event.double_click:
			selector.select_end(pos)
	elif event is InputEventMouseMotion and selector.is_moving:
		var pos = snapper.snap_position(get_local_mouse_position(), true)
		if is_pressed:
			selector.select_move(pos)
		else:
			selector.select_end(pos)
			

func process_selection_lasso(event, selector):
	if event is InputEventMouseMotion:
		var pos = snapper.snap_position(get_local_mouse_position(), true)
		if is_pressed:
			selector.select_move(pos)
		elif selector.is_operating:
			selector.select_end(pos)


func _input(event :InputEvent):
	if not project.current_cel or frozen:
		return
	
	if event is InputEventMouseButton:
		is_pressed = event.pressed
		operating.emit(state, not is_pressed)

	match state:
		Artboard.PENCIL:
			process_drawing_or_erasing(event, pencil)
		Artboard.BRUSH:
			process_drawing_or_erasing(event, brush)
		Artboard.ERASE:
			process_drawing_or_erasing(event, eraser)
		Artboard.CROP:
			pass
		Artboard.MOVE:
			pass
		Artboard.SELECT_RECTANGLE:
			process_selection(event, rect_selector)
		Artboard.SELECT_ELLIPSE:
			process_selection(event, ellipse_selector)
		Artboard.SELECT_POLYGON:
			process_selection_polygon(event, polygon_selector)
		Artboard.SELECT_LASSO:
			process_selection_lasso(event, lasso_selector)


func _draw():
	if not project.current_cel:
		return

	# Draw current frame layers
	for i in project.layers.size():
		var cels = project.current_frame.cels 
		if cels[i] is GroupCel:
			continue
		var modulate_color := Color(1, 1, 1, project.layers[i].opacity)
		if project.layers[i].is_visible_in_hierarchy():
			var tex = cels[i].image_texture
			draw_texture(tex, Vector2.ZERO, modulate_color)


func get_relative_mouse_position(): # other node need mouse location of canvas.
	var mpos = get_local_mouse_position()
	return Vector2i(round(mpos.x), round(mpos.y))


# cursor
func _on_curosr_updated(cursor):
	cursor_updated.emit(cursor)
	

# selection
func _on_selection_updated(rect :Rect2i):
	selection_updated.emit(rect)


# crop
func _on_crop_applied(rect :Rect2i):
	crop_applied.emit(rect)


# transform
func _on_transformer_updated(_rect :Rect2i):
	project.current_cel.update_texture()
	queue_redraw()


# snapping

func attach_snap_to(canvas_size:Vector2, guides:Array,
					symmetry_guide:SymmetryGuide, grid:Grid):
	snapper.guides = guides
	snapper.grid = grid
	snapper.symmetry_guide = symmetry_guide
	snapper.canvas_size = canvas_size


var snap_to_guide :bool :
	get: return snapper.snap_to_guide
	set(val): snapper.snap_to_guide = val


var snap_to_grid_center :bool :
	get: return snapper.snap_to_grid_center
	set(val): snapper.snap_to_grid_center = val


var snap_to_grid_boundary :bool :
	get: return snapper.snap_to_grid_boundary
	set(val): snapper.snap_to_grid_boundary = val

var snap_to_symmetry_guide :bool :
	get: return snapper.snap_to_symmetry_guide
	set(val): snapper.snap_to_symmetry_guide = val

