extends Control

var current_color := Color.WHITE
var current_drawer :BaseDrawer

@onready var artboard :SubViewportContainer = $Artboard

@onready var btn_1 = $BtnMove
@onready var btn_2 = $BtnPan
@onready var btn_3 = $BtnZoom
@onready var btn_4 = $BtnPencil
@onready var btn_5 = $BtnBrush
@onready var btn_6 = $BtnErase
@onready var btn_7 = $BtnSelect

@onready var btn_lock_guide = $BtnLockGuide

@onready var opt_stroke_dynamics = $OptStrokeBtn
@onready var opt_alpha_dynamics = $OptAlphaBtn
@onready var slider_stroke_width = $StrokeWidthSlider
@onready var slider_stroke_space = $StrokeSpaceSlider


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
	
	btn_lock_guide.pressed.connect(_on_btn_pressed.bind(btn_lock_guide))
	
	opt_stroke_dynamics.item_selected.connect(_on_stroke_dynamics)
	opt_alpha_dynamics.item_selected.connect(_on_alpha_dynamics)
	
	slider_stroke_width.value_changed.connect(_on_stroke_width_changed)
	slider_stroke_space.value_changed.connect(_on_stroke_space_changed)
	
	artboard.canvas.snapping_to(true, false, false)
	
	artboard.show_mouse_guide = false
	artboard.show_rulers = false
	artboard.show_guides = false
	artboard.show_grid_state = Grid.NONE
	artboard.show_symmetry_guide_state = SymmetryGuide.NONE
	
#	artboard.symmetry_guide_state = SymmetryGuide.HORIZONTAL_AXIS
	
#	var image = Image.new()
#	if image.load('res://test.png') == OK:
#		artboard.canvas.reference_image.set_image(image)
#		artboard.canvas.reference_image.scale = Vector2(0.2, 0.2)
#		artboard.canvas.reference_image.offset = Vector2(250, 100)
#
#	var color_1 = Color.RED
#	var color_2 = Color.GREEN
##	color_1.a *= 1.0
#	color_2.a = 0.5
#	color_1.a = 0.5
#	$ColorRect.color = color_2.blend(color_1)
	

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
		
		'BtnLockGuide':
			artboard.guides_locked = btn.button_pressed
			
		'BtnSelect':
			artboard.state = Artboard.SELECT_RECTANGLE
		
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
