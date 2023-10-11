extends Control

var current_color := Color.WHITE
var current_drawer :PixelDrawer


@onready var artboard :SubViewportContainer = $HBoxContainer/Artboard

@onready var btn_1 = $BtnMove
@onready var btn_2 = $BtnPan
@onready var btn_3 = $BtnZoom
@onready var btn_4 = $BtnPencil
@onready var btn_5 = $BtnBrush
@onready var btn_6 = $BtnErase
@onready var btn_7 = $BtnSelectRect
@onready var btn_8 = $BtnSelectCircle
@onready var btn_9 = $BtnSelectPolygon
@onready var btn_10 = $BtnSelectLasso
@onready var btn_11 = $BtnCrop
@onready var btn_12 = $BtnSelectMagic
@onready var btn_13 = $ColorPicker
@onready var btn_14 = $BtnContiguous
@onready var btn_15 = $BtnShading
@onready var btn_16 = $Bucket
@onready var btn_17 = $BtnShapeRect
@onready var btn_18 = $BtnShapeEllipse
@onready var btn_19 = $BtnShapeLine
@onready var btn_20 = $BtnShapePolygon

@onready var btn_lock_guide = $BtnLockGuide
@onready var btn_show_guide = $BtnShowGuide

@onready var opt_selection_mode = $OptSelectionMode
@onready var btn_center_selector = $BtnCenterSelector
@onready var btn_square_selector = $BtnSquareSelector

@onready var opt_stroke_dynamics = $OptStrokeBtn
@onready var opt_alpha_dynamics = $OptAlphaBtn
@onready var slider_stroke_width = $StrokeWidthSlider
@onready var slider_stroke_space = $StrokeSpaceSlider

@onready var transform_panel = $TransformPanel


func _init():
	InputMap.add_action('deselect_all')
	var evt_deselect_all := InputEventKey.new()
	evt_deselect_all.keycode = KEY_D
	evt_deselect_all.command_or_control_autoremap = true
	InputMap.action_add_event('deselect_all', evt_deselect_all)


func _ready():
		
	g.current_project = Project.new(Vector2i(400, 300))
	artboard.load_project(g.current_project)
	
	btn_1.pressed.connect(_on_btn_pressed.bind(btn_1))
	btn_2.pressed.connect(_on_btn_pressed.bind(btn_2))
	btn_3.pressed.connect(_on_btn_pressed.bind(btn_3))
	btn_4.pressed.connect(_on_btn_pressed.bind(btn_4))
	btn_5.pressed.connect(_on_btn_pressed.bind(btn_5))
	btn_6.pressed.connect(_on_btn_pressed.bind(btn_6))
	btn_7.pressed.connect(_on_btn_pressed.bind(btn_7))
	btn_8.pressed.connect(_on_btn_pressed.bind(btn_8))
	btn_9.pressed.connect(_on_btn_pressed.bind(btn_9))
	btn_10.pressed.connect(_on_btn_pressed.bind(btn_10))
	btn_11.pressed.connect(_on_btn_pressed.bind(btn_11))
	btn_12.pressed.connect(_on_btn_pressed.bind(btn_12))
	btn_13.pressed.connect(_on_btn_pressed.bind(btn_13))
	btn_14.pressed.connect(_on_btn_pressed.bind(btn_14))
	btn_15.pressed.connect(_on_btn_pressed.bind(btn_15))
	btn_16.pressed.connect(_on_btn_pressed.bind(btn_16))
	btn_17.pressed.connect(_on_btn_pressed.bind(btn_17))
	btn_18.pressed.connect(_on_btn_pressed.bind(btn_18))
	btn_19.pressed.connect(_on_btn_pressed.bind(btn_19))
	btn_20.pressed.connect(_on_btn_pressed.bind(btn_20))
	
	btn_lock_guide.pressed.connect(_on_btn_pressed.bind(btn_lock_guide))
	btn_show_guide.pressed.connect(_on_btn_pressed.bind(btn_show_guide))
	
	opt_selection_mode.item_selected.connect(_on_selection_mode)
	
	btn_center_selector.pressed.connect(_on_btn_pressed.bind(btn_center_selector))
	btn_square_selector.pressed.connect(_on_btn_pressed.bind(btn_square_selector))
	
	opt_stroke_dynamics.item_selected.connect(_on_stroke_dynamics)
	opt_alpha_dynamics.item_selected.connect(_on_alpha_dynamics)
	
	slider_stroke_width.value_changed.connect(_on_stroke_width_changed)
	slider_stroke_space.value_changed.connect(_on_stroke_space_changed)
	
	artboard.snap_to_guide = true
	artboard.snap_to_symmetry_guide = true
	
	artboard.show_mouse_guide = false
	artboard.show_rulers = true
	artboard.show_guides = true
	artboard.show_grid_state = Grid.NONE
	artboard.show_symmetry_guide_state = SymmetryGuide.CROSS_AXIS
#	artboard.symmetry_guide_state = SymmetryGuide.HORIZONTAL_AXIS


func set_state(state):
	artboard.state = state
	match state:
		Operate.MOVE:
			transform_panel.subscribe(artboard.canvas.move_sizer)
		Operate.CROP:
			transform_panel.subscribe(artboard.canvas.crop_sizer)
		Operate.SELECT_RECTANGLE:
			transform_panel.subscribe(artboard.canvas.selection)
		Operate.SELECT_ELLIPSE:
			transform_panel.subscribe(artboard.canvas.selection)
		Operate.SELECT_POLYGON:
			transform_panel.subscribe(artboard.canvas.selection)
		Operate.SELECT_LASSO:
			transform_panel.subscribe(artboard.canvas.selection)
		Operate.SELECT_MAGIC:
			transform_panel.subscribe(artboard.canvas.selection)
		Operate.SHAPE_ELLIPSE:
			transform_panel.subscribe(artboard.canvas.silhouette)
		Operate.SHAPE_RECTANGLE:
			transform_panel.subscribe(artboard.canvas.silhouette)
		Operate.SHAPE_LINE:
			transform_panel.subscribe(artboard.canvas.silhouette)
		_:
			transform_panel.unsubscribe()


func _on_btn_pressed(btn):
	match btn.name:
		'BtnMove':
			set_state(Operate.MOVE)
		'BtnPan':
			set_state(Operate.DRAG)
		'BtnZoom':
			set_state(Operate.ZOOM)
		'BtnPencil':
			set_state(Operate.PENCIL)
			if current_color == Color.RED:
				current_color = Color.GREEN
			else:
				current_color = Color.RED
			current_drawer = artboard.canvas.drawer_pencil
			current_drawer.stroke_color = current_color
			btn.modulate = current_color
			
		'BtnBrush':
			set_state(Operate.BRUSH)
			if current_color == Color.RED:
				current_color = Color.GREEN
			else:
				current_color = Color.RED
			var tmp_color = Color(current_color)
#			tmp_color.a *= 0.5
			current_drawer = artboard.canvas.drawer_brush
			current_drawer.stroke_color = tmp_color
			btn.modulate = current_color
			
		'BtnErase':
			set_state(Operate.ERASE)
			current_drawer = artboard.canvas.drawer_eraser
		'BtnShading':
			set_state(Operate.SHADING)
			current_drawer = artboard.canvas.drawer_shading
			current_drawer.opt_amount = 5
			current_drawer.opt_hue_amount = 50
			current_drawer.opt_sat_amount = 50
			current_drawer.opt_value_amount = 150
			current_drawer.opt_simple_shading = false
			current_drawer.opt_lighten = true
		'BtnCrop':
			set_state(Operate.CROP)
		'Bucket':
			set_state(Operate.BUCKET)
		'BtnLockGuide':
			artboard.guides_locked = btn.button_pressed
		'BtnShowGuide':
			artboard.show_guides = btn.button_pressed
		'BtnSelectRect':
			set_state(Operate.SELECT_RECTANGLE)
		'BtnSelectCircle':
			set_state(Operate.SELECT_ELLIPSE)
		'BtnSelectPolygon':
			set_state(Operate.SELECT_POLYGON)
		'BtnSelectLasso':
			set_state(Operate.SELECT_LASSO)
		'BtnSelectMagic':
			set_state(Operate.SELECT_MAGIC)
			artboard.canvas.selector_magic.tolerance = 0
		'BtnShapeRect':
			set_state(Operate.SHAPE_RECTANGLE)
			artboard.canvas.silhouette.opt_as_square = false
			artboard.canvas.silhouette.opt_from_center = true
			artboard.canvas.silhouette.opt_fill = false
			artboard.canvas.silhouette.stroke_weight = 2
		'BtnShapeEllipse':
			set_state(Operate.SHAPE_ELLIPSE)
			artboard.canvas.silhouette.opt_as_square = false
			artboard.canvas.silhouette.opt_from_center = false
			artboard.canvas.silhouette.opt_fill = false
			artboard.canvas.silhouette.stroke_weight = 2
		'BtnShapeLine':
			set_state(Operate.SHAPE_LINE)
			artboard.canvas.silhouette.opt_as_square = false
			artboard.canvas.silhouette.opt_from_center = false
			artboard.canvas.silhouette.opt_fill = false
			artboard.canvas.silhouette.stroke_weight = 5
		'BtnShapePolygon':
			set_state(Operate.SHAPE_POLYGON)
			artboard.canvas.silhouette.opt_as_square = false
			artboard.canvas.silhouette.opt_from_center = false
			artboard.canvas.silhouette.opt_fill = false
			artboard.canvas.silhouette.stroke_weight = 2
		'ColorPicker':
			set_state(Operate.COLOR_PICK)
		'BtnCenterSelector':
			artboard.canvas.selection.opt_from_center = btn.button_pressed
		'BtnSquareSelector':
			artboard.canvas.selection.opt_as_square = btn.button_pressed
		'BtnContiguous':
			artboard.canvas.selector_magic.opt_contiguous = btn.button_pressed
		

	if current_drawer:
		opt_stroke_dynamics.disabled = not current_drawer.allow_dyn_stroke_width
		opt_alpha_dynamics.disabled = not current_drawer.allow_dyn_stroke_alpha
		slider_stroke_width.value = current_drawer.stroke_width
		slider_stroke_space.value = current_drawer.stroke_spacing.x


func _on_stroke_dynamics(index):
	match index:
		0 : artboard.canvas.dynamics_stroke_width = Dynamics.NONE
		1 : artboard.canvas.dynamics_stroke_width = Dynamics.PRESSURE
		2 : artboard.canvas.dynamics_stroke_width = Dynamics.VELOCITY


func _on_alpha_dynamics(index):
	match index:
		0 : artboard.canvas.dynamics_stroke_alpha = Dynamics.NONE
		1 : artboard.canvas.dynamics_stroke_alpha = Dynamics.PRESSURE
		2 : artboard.canvas.dynamics_stroke_alpha = Dynamics.VELOCITY


func _on_stroke_width_changed(val):
	print('Stroke Width: ', val)
	if current_drawer:
		current_drawer.stroke_width = val


func _on_stroke_space_changed(val):
	print('Stroke Space: ', val)
	if current_drawer:
		current_drawer.stroke_spacing = Vector2i(val, val)


func _on_selection_mode(val):
	artboard.canvas.selection.mode = val
