class_name Canvas extends Node2D

signal cursor_changed(cursor)
signal selection_changed(rect)
signal operating(operate_state, operater, is_finished)

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

var zoom := Vector2.ONE :
	set(val):
		zoom = val
		selection.zoom_ratio = (zoom.x + zoom.y) / 2

var frozen := false # temporary prevent canvas operations.

var state := Artboard.NONE:
	set(val):
		state = val
		indicator.hide_indicator()  # not all state need indicator

@onready var indicator :Indicator = $Indicator
@onready var selection :Selection = $Selection
@onready var crop_rect :CropRect = $CropRect

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
#@onready var crop_rect :CropRect = $CropRect


func _ready():
#	onion_past.type = onion_past.PAST
#	onion_past.blue_red_color = Color.RED
#	onion_future.type = onion_future.FUTURE
#	onion_future.blue_red_color = Color.BLUE
#
#	selection.gizmo_hovered.connect(_on_selection_gizmo_hovered)
#	selection.gizmo_unhovered.connect(_on_selection_gizmo_unhovered)
	
	# attach selection to selector
	rect_selector.selection = selection
	ellipse_selector.selection = selection
	polygon_selector.selection = selection
	lasso_selector.selection = selection
	selection.selected.connect(_on_selection_updated)
	
	pencil.mask = selection.mask
	brush.mask = selection.mask
	eraser.mask = selection.mask
	selection.mask = selection.mask


func attach_project(proj):
	project = proj
	
	if project.current_cel is PixelCel:
		pencil.image = project.current_cel.image
		brush.image = project.current_cel.image
		eraser.image = project.current_cel.image
	
	selection.size = project.size
	crop_rect.size = project.size


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
			operating.emit(state, drawer, false)
			queue_redraw()
				
		elif drawer.is_drawing:
			drawer.draw_end(pos)
			project.current_cel.update_texture()
			operating.emit(state, drawer, true)
			queue_redraw()


func process_selection(event, selector):
	if event is InputEventMouseMotion:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			selector.select_move(pos)
			operating.emit(state, selector, false)
		elif selector.is_operating:
			selector.select_end(pos)
			operating.emit(state, selector, true)


func process_selection_polygon(event, selector):
	if event is InputEventMouseButton:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed and not event.double_click:
			selector.select_move(pos)
			operating.emit(state, selector, false)
		elif selector.is_selecting and event.double_click:
			selector.select_end(pos)
			operating.emit(state, selector, true)
	elif event is InputEventMouseMotion and selector.is_moving:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			selector.select_move(pos)
			operating.emit(state, selector, false)
		else:
			selector.select_end(pos)
			operating.emit(state, selector, true)
			

func process_selection_lasso(event, selector):
	if event is InputEventMouseMotion:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			selector.select_move(pos)
			operating.emit(state, selector, false)
		elif selector.is_operating:
			selector.select_end(pos)
			operating.emit(state, selector, true)


func _input(event :InputEvent):
	if not project.current_cel or frozen:
		return
	
	if event is InputEventMouseButton:
		is_pressed = event.pressed

	match state:
		Artboard.PENCIL:
			process_drawing_or_erasing(event, pencil)
		Artboard.BRUSH:
			process_drawing_or_erasing(event, brush)
		Artboard.ERASE:
			process_drawing_or_erasing(event, eraser)
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


func get_relative_mouse_position():
	var mpos = get_local_mouse_position()
	return Vector2i(round(mpos.x), round(mpos.y))


# selection
func _on_selection_updated(sel_rect :Rect2i):
	selection_changed.emit(sel_rect)


# gizmo
func _on_selection_gizmo_hovered(gizmo):
	cursor_changed.emit(gizmo.cursor)


func _on_selection_gizmo_unhovered(_gizmo):
	cursor_changed.emit(null)


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
