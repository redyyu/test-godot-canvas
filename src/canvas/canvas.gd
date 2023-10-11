class_name Canvas extends Node2D

signal cropped(crop_rect)
signal cursor_changed(cursor)
signal operating(operate_state, is_finished)
# let parent to know when should block some other actions.
# for improve useblilty.


var state := Operate.NONE:
	set = set_state

var project :Project
var current_operator :Variant = null
var size :Vector2i :
	get:
		if project:
			return project.size
		else:
			return Vector2i.ZERO

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
	set = set_zoom_ratio


var color_pick := ColorPick.new()

@onready var indicator :Indicator = $Indicator
@onready var selection :Selection = $Selection
@onready var crop_sizer :CropSizer = $CropSizer
@onready var move_sizer :MoveSizer = $MoveSizer

@onready var silhouette :Silhouette = $Silhouette

@onready var selector_rect := RectSelector.new(selection)
@onready var selector_ellipse := EllipseSelector.new(selection)
@onready var selector_polygon := PolygonSelector.new(selection)
@onready var selector_lasso := LassoSelector.new(selection)
@onready var selector_magic := MagicSelector.new(selection)

@onready var drawer_pencil := PencilDrawer.new(selection.mask)
@onready var drawer_brush := BrushDrawer.new(selection.mask)
@onready var drawer_eraser := EraseDrawer.new(selection.mask)
@onready var drawer_shading := ShadingDrawer.new(selection.mask)

@onready var bucket := Bucket.new(selection.mask)

@onready var shaper_rect := RectShaper.new(silhouette)
@onready var shaper_ellipse := EllipseShaper.new(silhouette)


#var mirror_view :bool = false
#var draw_pixel_grid :bool = false
#var grid_draw_over_tile_mode :bool = false
#var shape_perfect :bool = false
#var shape_center :bool = false

#var onion_skinning :bool = false
#var onion_skinning_past_rate := 1.0
#var onion_skinning_future_rate := 1.0

#@onready var tile_mode :Node2D = $TileMode
#@onready var onion_past :Node2D = $OnionPast
#@onready var onion_future :Node2D = $OnionFuture


func _ready():
#	onion_past.type = onion_past.PAST
#	onion_past.blue_red_color = Color.RED
#	onion_future.type = onion_future.FUTURE
#	onion_future.blue_red_color = Color.BLUE
	
	bucket.mask = selection.mask
	
	var snapping_hook = func(rect:Rect2i, pos :Vector2i) -> Vector2i:
		return snapper.snap_boundary_position(rect, pos)
	
	crop_sizer.crop_canvas.connect(crop)
	crop_sizer.cursor_changed.connect(_on_cursor_changed)
	crop_sizer.inject_snapping(snapping_hook)
	
	move_sizer.refresh_canvas.connect(refresh)
	move_sizer.cursor_changed.connect(_on_cursor_changed)
	move_sizer.inject_snapping(snapping_hook)
	
	bucket.color_filled.connect(refresh)
	
	silhouette.refresh_canvas.connect(refresh)
	silhouette.inject_snapping(snapping_hook)
	
	selection.inject_snapping(snapping_hook)


func attach_project(proj):
	project = proj
	
	selection.size = project.size
	
	silhouette.attach(project.current_cel.get_image())
	
	drawer_brush.attach(project.current_cel.get_image())
	drawer_pencil.attach(project.current_cel.get_image())
	drawer_eraser.attach(project.current_cel.get_image())
	drawer_shading.attach(project.current_cel.get_image())
	
	bucket.attach(project.current_cel.get_image())
	set_state(state)  # trigger state changing to init settings.


func refresh():
	project.current_cel.update_texture()
	queue_redraw()


func crop(crop_rect :Rect2i):
	project.crop_to(crop_rect)
	

# temporary prevent canvas operations.
func frozen(frozen_it := false): 
	set_process_input(not frozen_it)


func set_state(val):  # triggered when state changing.
	# allow change without really changed val, trigger funcs in setter.
	state = val
	is_pressed = false
	
	indicator.hide_indicator()  # not all state need indicator
	
	if state == Operate.CROP:
		move_sizer.cancel()
		crop_sizer.launch(project.size)
		selection.deselect()
	elif state == Operate.MOVE:
		crop_sizer.cancel()
		move_sizer.lanuch(project.current_cel.get_image(), selection.mask)
		# selection must clear after mover setted, 
		# mover still need it once.
		selection.deselect()
	else:
		move_sizer.apply()
		crop_sizer.cancel()


func set_zoom_ratio(val):
	if zoom == val:
		return
	zoom = val
	var zoom_ratio = (zoom.x + zoom.y) / 2
	selection.zoom_ratio = zoom_ratio
	crop_sizer.zoom_ratio = zoom_ratio
	move_sizer.zoom_ratio = zoom_ratio


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
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			selector.select_move(pos)
		elif selector.is_operating:
			selector.select_end(pos)


func process_selection_polygon(event, selector):
	if event is InputEventMouseButton:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed and not event.double_click:
			selector.select_move(pos)
		elif selector.is_selecting and event.double_click:
			selector.select_end(pos)
	elif event is InputEventMouseMotion and selector.is_moving:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			selector.select_move(pos)
		else:
			selector.select_end(pos)
			

func process_selection_lasso(event, selector):
	if event is InputEventMouseMotion:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			selector.select_move(pos)
		elif selector.is_operating:
			selector.select_end(pos)


func process_selection_magic(event, selector):
	if event is InputEventMouseButton:
		var pos = get_local_mouse_position()
		if is_pressed:
			selector.image = project.current_cel.get_image()
			selector.select_move(pos)
		elif selector.is_operating:
			selector.select_end(pos)
			
	elif event is InputEventMouseMotion and selector.is_moving:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			selector.select_move(pos)
		elif selector.is_operating:
			selector.select_end(pos)


func process_color_pick(event):
	if event is InputEventMouseButton:
		if is_pressed:
			color_pick.merge_image(project.current_frame.get_images(),
								   PixelCel.IMAGE_FORMAT)
	elif event is InputEventMouseMotion:
		if is_pressed:
			var pos = get_local_mouse_position()
			color_pick.pick(pos)


func process_bucket_fill(event):
	if event is InputEventMouseButton:
		if is_pressed:
			var pos = get_local_mouse_position()
			bucket.fill(pos)


func process_shape(event, shaper):
	if event is InputEventMouseButton:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			if not silhouette.has_point(pos):
				shaper.apply()
			# DO NOT depaned doublie_clieck here, pressed always come first.
	elif event is InputEventMouseMotion:
		var pos = snapper.snap_position(get_local_mouse_position())
		if is_pressed:
			shaper.shape_move(pos)
		elif shaper.is_operating:
			shaper.shape_end(pos)


func _input(event :InputEvent):
	if not project.current_cel:
		return
	
	if event is InputEventMouseButton:
		is_pressed = event.pressed
		operating.emit(state, not is_pressed)

	match state:
		Operate.PENCIL:
			process_drawing_or_erasing(event, drawer_pencil)
		Operate.BRUSH:
			process_drawing_or_erasing(event, drawer_brush)
		Operate.ERASE:
			process_drawing_or_erasing(event, drawer_eraser)
		Operate.SHADING:
			process_drawing_or_erasing(event, drawer_shading)
		Operate.CROP:
			pass
		Operate.MOVE:
			pass
		Operate.SELECT_RECTANGLE:
			process_selection(event, selector_rect)
		Operate.SELECT_ELLIPSE:
			process_selection(event, selector_ellipse)
		Operate.SELECT_POLYGON:
			process_selection_polygon(event, selector_polygon)
		Operate.SELECT_LASSO:
			process_selection_lasso(event, selector_lasso)
		Operate.SELECT_MAGIC:
			process_selection_magic(event, selector_magic)
		Operate.SHAPE_RECTANGLE:
			process_shape(event, shaper_rect)
		Operate.SHAPE_ELLIPSE:
			process_shape(event, shaper_ellipse)
		Operate.COLOR_PICK:
			process_color_pick(event)
		Operate.BUCKET:
			process_bucket_fill(event)


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
func _on_cursor_changed(cursor):
	cursor_changed.emit(cursor)


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

