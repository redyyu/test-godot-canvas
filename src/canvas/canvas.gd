extends Node2D

class_name Canvas

var pencil := PencilDrawer.new()
var brush := BrushDrawer.new()
var eraser := EraseDrawer.new()

var project :Project

const DEFAULT_PEN_PRESSURE := 1.0
const DEFAULT_PEN_VELOCITY := 1.0

var pressure_min_thres := 0.0
var pressure_max_thres := 1.0
var velocity_min_thres := 0.0
var velocity_max_thres := 1.0

var is_pressed := false
var state := ArtboardState.NONE
var dynamics := Dynamics.NONE

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
@onready var indicators :Node2D = $Indicators
@onready var previews :Node2D = $Previews
@onready var mouse_guide_container :Node2D = $MouseGuideContainer


func _ready():
	pass
#	onion_past.type = onion_past.PAST
#	onion_past.blue_red_color = Color.RED
#	onion_future.type = onion_future.FUTURE
#	onion_future.blue_red_color = Color.BLUE
#
#	selection.gizmo_selected.connect(_on_stop_draw)
#	selection.gizmo_released.connect(_on_reset_draw)
#	selection.selection_map_changed.connect(_on_selection_map_changed)


func set_canvas(proj):
	project = proj
	if project.current_cel is PixelCel:
		pencil.image = project.current_cel.image
		eraser.image = project.current_cel.image


func set_pencil(stroke_width,
				stroke_color = null,
				stroke_spacing = null,
				fill_inside := false):
	if stroke_width != null:
		pencil.stroke_width = stroke_width
	
	if stroke_color != null:
		pencil.stroke_color = stroke_color
	
	if stroke_spacing is Vector2i:
		pencil.stroke_spacing = stroke_spacing

	pencil.fill_inside = bool(fill_inside)


func set_brush(stroke_width, stroke_color = null, stroke_spacing = null):
	if stroke_width != null:
		brush.stroke_width = stroke_width
	
	if stroke_color != null:
		brush.stroke_color = stroke_color
	
	if stroke_spacing is Vector2i:
		brush.stroke_spacing = stroke_spacing


func set_eraser(eraser_size):
	if eraser_size != null:
		eraser.stroke_width = eraser_size
	

func prepare_pressure(pressure:float) -> float:
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
		var pos = get_local_mouse_position()
		if drawer.can_draw(pos) and project.current_cel is PixelCel:
			if is_pressed:
				match dynamics:
					Dynamics.PRESSURE:
						var pressure = prepare_pressure(event.pressure)
						drawer.set_stroke_dynamics(pressure)
						drawer.set_alpha_dynamics(pressure)
					Dynamics.VELOCITY:
						var velocity = prepare_velocity(event.velocity)
						drawer.set_stroke_dynamics(velocity)
						drawer.set_alpha_dynamics(velocity)
					_:
						drawer.set_stroke_dynamics()
						drawer.set_alpha_dynamics()
				drawer.draw_move(pos)
			elif drawer.is_drawing:
				drawer.draw_end(pos)
			project.current_cel.update_texture()
			queue_redraw()


func _input(event :InputEvent):
	if not project.current_cel:
		return
#	if event is InputEventMouse:
#		var mouse_pos = get_local_mouse_position()
#		var tmp_transform := get_canvas_transform().affine_inverse()
#		var current_pixel = tmp_transform.basis_xform(mouse_pos) + tmp_transform.origin
#		queue_redraw()
	if event is InputEventMouseButton:
		is_pressed = event.pressed

	match state:
		ArtboardState.PENCIL:
			process_drawing_or_erasing(event, pencil)
		ArtboardState.BRUSH:
			process_drawing_or_erasing(event, brush)
		ArtboardState.ERASE:
			process_drawing_or_erasing(event, eraser)


func _draw():
	if not project.current_cel:
		return
#	var position_tmp := position
#	var scale_tmp := scale
#	if Global.mirror_view:
#		position_tmp.x = position_tmp.x + Global.current_project.size.x
#		scale_tmp.x = -1
#	draw_set_transform(position_tmp, 0.0, scale_tmp)
	# Draw current frame layers
	for i in project.layers.size():
		var cels = project.current_frame.cels 
		if cels[i] is GroupCel:
			continue
		var modulate_color := Color(1, 1, 1, project.layers[i].opacity)
		if project.layers[i].is_visible_in_hierarchy():
			var tex = cels[i].image_texture
			draw_texture(tex, Vector2.ZERO, modulate_color)


#	current_drawer.queue_redraw()
#	if Global.current_project.tiles.mode != Tiles.MODE.NONE:
#		tile_mode.queue_redraw()
#	draw_set_transform(position, 0.0, Vector2.ONE)
	


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
