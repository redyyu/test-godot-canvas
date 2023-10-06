extends Control

var current_color := Color.WHITE
var current_drawer :PixelDrawer
var current_selector :BaseSelector


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
	
	artboard.transform_changed.connect(_on_transfrom_changed)
	artboard.project_cropped.connect(_on_project_cropped)
	
	transform_panel.pivot_updated.connect(_on_pivot_updated)
	transform_panel.size_updated.connect(_on_size_updated)
	transform_panel.position_updated.connect(_on_position_updated)



#	var image = Image.new()
#	if image.load('res://test.png') == OK:
#		artboard.canvas.reference_image.set_image(image)
#		artboard.canvas.reference_image.scale = Vector2(0.2, 0.2)
#		artboard.canvas.reference_image.offset = Vector2(250, 100)

	

func _on_btn_pressed(btn):
	match btn.name:
		'BtnMove':
			artboard.state = Artboard.MOVE
			current_drawer = null
		'BtnPan':
			artboard.state = Artboard.DRAG
			current_drawer = null
		'BtnZoom':
			artboard.state = Artboard.ZOOM
			current_drawer = null
			
		'BtnPencil':
			artboard.state = Artboard.PENCIL
			if current_color == Color.RED:
				current_color = Color.GREEN
			else:
				current_color = Color.RED
			current_drawer = artboard.canvas.pencil
			current_drawer.stroke_color = current_color
			btn.modulate = current_color
			
		'BtnBrush':
			artboard.state = Artboard.BRUSH
			if current_color == Color.RED:
				current_color = Color.GREEN
			else:
				current_color = Color.RED
			var tmp_color = Color(current_color)
#			tmp_color.a *= 0.5
			current_drawer = artboard.canvas.brush
			current_drawer.stroke_color = tmp_color
			btn.modulate = current_color
			
		'BtnErase':
			artboard.state = Artboard.ERASE
			current_drawer = artboard.canvas.eraser
			
		'BtnCrop':
			artboard.state = Artboard.CROP
		
		'BtnLockGuide':
			artboard.guides_locked = btn.button_pressed
		
		'BtnShowGuide':
			artboard.show_guides = btn.button_pressed
			
		'BtnSelectRect':
			artboard.state = Artboard.SELECT_RECTANGLE
			current_selector = artboard.canvas.rect_selector
		
		'BtnSelectCircle':
			artboard.state = Artboard.SELECT_ELLIPSE
			current_selector = artboard.canvas.ellipse_selector
		
		'BtnSelectPolygon':
			artboard.state = Artboard.SELECT_POLYGON
			current_selector = artboard.canvas.polygon_selector
		
		'BtnSelectLasso':
			artboard.state = Artboard.SELECT_LASSO
			current_selector = artboard.canvas.lasso_selector
		
		'BtnCenterSelector':
			artboard.apply_select_as_center(btn.button_pressed)
		
		'BtnSquareSelector':
			artboard.apply_select_as_square(btn.button_pressed)
		
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
	artboard.apply_selection_mode(val)


func _on_pivot_updated(val):
	artboard.apply_pivot_point(val)
	

func _on_size_updated(val):
	artboard.apply_resize(val)


func _on_position_updated(val):
	artboard.apply_moveto(val)
	

func _on_transfrom_changed(rect :Rect2i, rel_pos :Vector2i, status :bool):
	rect.position = rel_pos
	transform_panel.set_rect(rect, status)


func _on_project_cropped(rect :Rect2i):
	print('Crop Image: ', rect)	
