extends Node2D

class_name Canvas

var current_pixel := Vector2.ZERO
#var sprite_changed_this_frame = false  ## For optimization purposes
var camera_zoom := Vector2.ZERO
var move_preview_location = Vector2.ZERO
var mouse_pos :Vector2 = Vector2.ZERO
#var mirror_view :bool = false
#var draw_pixel_grid :bool = false
#var grid_draw_over_tile_mode :bool = false
#var shape_perfect :bool = false
#var shape_center :bool = false

#var onion_skinning :bool = false
#var onion_skinning_past_rate := 1.0
#var onion_skinning_future_rate := 1.0

@onready var current_display :SubViewport = $CurrentDisplay
@onready var current_drawer :Node2D = $CurrentDisplay/CurrentDrawer
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
	

func set_canvas_size(canvas_size :Vector2i):
	current_display.size = canvas_size
	

func get_canvas_size() -> Vector2i:
	return current_display.size


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
func update_zoom(zoom_val :Vector2):
	camera_zoom = zoom_val
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
