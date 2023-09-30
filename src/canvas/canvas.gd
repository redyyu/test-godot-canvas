class_name Canvas extends Node2D

signal cursor_changed(cursor)

var pencil := PencilDrawer.new()
var brush := BrushDrawer.new()
var eraser := EraseDrawer.new()

var rect_selector := RectSelector.new()
var ellipse_selector := EllipseSelector.new()
var polygon_selector := PolygonSelector.new()
var lasso_selector := LassoSelector.new()

var selected_area := Rect2i(Vector2i.ZERO, Vector2i.ZERO)

var project :Project

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
@onready var indicator :Node2D = $Indicator
@onready var selection :Node2D = $Selection


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
	selection.selected.connect(_on_selected_updated)


func attach_project(proj):
	project = proj
	
	if project.current_cel is PixelCel:
		pencil.image = project.current_cel.image
		brush.image = project.current_cel.image
		eraser.image = project.current_cel.image
		selection.size = project.size


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
		
		if is_pressed:
			if drawer.can_draw(pos) and project.current_cel is PixelCel:
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
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			selector.select_move(pos)
		elif selector.is_selecting:
			selector.select_end(pos)


func process_selection_polygon(event, selector):
	if event is InputEventMouseButton:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed and not event.double_click:
			selector.select_move(pos)
		elif event.double_click and selector.is_selecting:
			selector.select_end(pos)
			

func process_selection_lasso(event, selector):
	if event is InputEventMouseMotion:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			selector.select_move(pos)
		elif selector.is_selecting:
			selector.select_end(pos)


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


#func _on_stop_draw():
#	g.can_draw = false
#
#
#func _on_reset_draw():
#	g.can_draw = false
#
#
#func _on_selection_map_changed(sel_map :SelectionMap):
#	g.current_project.selection_map = sel_map
#	g.current_project.selection_map_changed()
#
#
#func _draw():
#	var project = g.current_project
#	var layers = project.layers
#	var current_frame = project.current_frame
#	var current_cels :Array = (project.frames[current_frame].cels)
#
#	var position_tmp = position
#	var scale_tmp = scale
#	if mirror_view:
#		position_tmp.x = position_tmp.x + project.size.x
#		scale_tmp.x = -1
#	draw_set_transform(position_tmp, rotation, scale_tmp)
#	# Draw current frame layers
#	for i in project.layers.size():
#		if current_cels[i] is GroupCel:
#			continue
#		var modulate_color := Color(1, 1, 1, current_cels[i].opacity)
#		if layers[i].is_visible_in_hierarchy():
#			var selected_layers = []
#			if move_preview_location != Vector2.ZERO:
#				for cel_pos in project.selected_cels:
#					if cel_pos[0] == current_frame:
#						if layers[cel_pos[1]].can_layer_get_drawn():
#							selected_layers.append(cel_pos[1])
#			if i in selected_layers:
#				draw_texture(current_cels[i].image_texture, 
#							 move_preview_location,
#							 modulate_color)
#			else:
#				draw_texture(current_cels[i].image_texture,
#							 Vector2.ZERO,
#							 modulate_color)
#
#	if onion_skinning:
#		refresh_onion()
#	currently_visible_frame.size = project.size
#	current_frame_drawer.queue_redraw()
#	if project.tiles.mode != Tiles.MODE.NONE:
#		tile_mode.queue_redraw()
#	draw_set_transform(position, rotation, scale)
#
#
#func _input(event: InputEvent):
#	if event is InputEventMouse:
#		var tmp_transform := get_canvas_transform().affine_inverse()
#		current_pixel = tmp_transform.basis_xform(mouse_pos) + tmp_transform.origin
#		queue_redraw()
#
#

#	selection.update_zoom(camera_zoom)
#
#
#func update_texture(layer_i :int, frame_i :int = -1):
#	var project = g.current_project
#
#	if frame_i == -1:
#		frame_i = project.current_frame
#
#	if frame_i < project.frames.size() and layer_i < project.layers.size():
#		var current_cel: BaseCel = project.frames[frame_i].cels[layer_i]
#		current_cel.update_texture()
#
#
#func update_selected_cels_textures():
#	var project = g.current_project
#	for cel_index in project.selected_cels:
#		var frame_index: int = cel_index[0]
#		var layer_index: int = cel_index[1]
#		if frame_index < project.frames.size() and layer_index < project.layers.size():
#			var current_cel: BaseCel = project.frames[frame_index].cels[layer_index]
#			current_cel.update_texture()
#
#
#func refresh_onion():
#	onion_past.queue_redraw()
#	onion_future.queue_redraw()
#
#
#func refresh_pixel_grid():
#	pixel_grid.camera_zoom = camera_zoom
#	pixel_grid.draw_pixel_grid = draw_pixel_grid
#	pixel_grid.queue_redraw()
#
#
#func refresh_grid():
#	if grid_draw_over_tile_mode:
#		grid.target_rect = g.current_project.tiles.get_bounding_rect()
#	else:
#		grid.target_rect = Rect2i(Vector2.ZERO, g.current_project.size)
#	grid.queue_redraw()
#
#
#func refresh_tile_mode():
#	tile_mode.mirror_view = mirror_view
#	tile_mode.currently_visible_frame = currently_visible_frame
#	tile_mode.queue_redraw()
#
#
#func update_selection():
#	var project = g.current_project
#	selection.current_size = project.size
#	selection.current_layer = project.layers[project.current_layer]
#	selection.camera_zoom = camera_zoom
#	selection.shape_perfect = shape_perfect
#	selection.shape_center = shape_center


# selection
func _on_selected_updated(sel_rect :Rect2i):
	selected_area = sel_rect


# gizmo
func _on_selection_gizmo_hovered(gizmo):
	cursor_changed.emit(gizmo.cursor)


func _on_selection_gizmo_unhovered(_gizmo):
	cursor_changed.emit(null)


# snapping

func attach_snap_to(size:Vector2, guides:Array, grid:Grid):
	snapper.guides = guides
	snapper.grid = grid
	snapper.canvas_size = size


func snap_to_guide(val := false):
	snapper.snap_to_guides = val


func snap_to_grid_center(val := false):
	snapper.snap_to_grid_center = val


func snap_to_grid_boundary(val := false):
		snapper.snap_to_grid_boundary = val
