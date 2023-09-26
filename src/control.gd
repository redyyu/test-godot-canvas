extends Control

var current_color := Color.WHITE

@onready var artboard :SubViewportContainer = $Artboard

@onready var btn_1 = $BtnNone
@onready var btn_2 = $BtnPan
@onready var btn_3 = $BtnZoom
@onready var btn_4 = $BtnPencil
@onready var btn_5 = $BtnBrush
@onready var btn_6 = $BtnErase

@onready var btn_dynamics = $OptBtn


func _ready():
	g.current_project = Project.new(Vector2i(400, 300))
	
	artboard.load_project(g.current_project)
	
	btn_1.pressed.connect(_on_btn_pressed.bind(btn_1))
	btn_2.pressed.connect(_on_btn_pressed.bind(btn_2))
	btn_3.pressed.connect(_on_btn_pressed.bind(btn_3))
	btn_4.pressed.connect(_on_btn_pressed.bind(btn_4))
	btn_5.pressed.connect(_on_btn_pressed.bind(btn_5))
	btn_6.pressed.connect(_on_btn_pressed.bind(btn_6))
	
	btn_dynamics.item_selected.connect(_on_dynamics_btn)
	
#	var color_1 = Color.RED
#	var color_2 = Color.GREEN
##	color_1.a *= 1.0
#	color_2.a = 0.5
#	color_1.a = 0.5
#	$ColorRect.color = color_2.blend(color_1)
	

func _on_btn_pressed(btn):
	match btn.name:
		'BtnNone':
			artboard.activate_state(ArtboardState.NONE)
		'BtnPan':
			artboard.activate_state(ArtboardState.DRAG)
		'BtnZoom':
			artboard.activate_state(ArtboardState.ZOOM)
		'BtnPencil':
			artboard.activate_state(ArtboardState.PENCIL)
			if current_color == Color.RED:
				current_color = Color.GREEN
			else:
				current_color = Color.RED
			var tmp_color = Color.GREEN.blend(Color.RED)
			tmp_color.a *= 0.6
			artboard.canvas.set_pencil(30, tmp_color, null)
			btn.modulate = current_color
		'BtnBrush':
			artboard.activate_state(ArtboardState.BRUSH)
			if current_color == Color.RED:
				current_color = Color.GREEN
			else:
				current_color = Color.RED
			var tmp_color = Color(current_color)
			tmp_color.a *= 0.6
			artboard.canvas.set_brush(30, tmp_color, null)
			btn.modulate = current_color
		'BtnErase':
			artboard.activate_state(ArtboardState.ERASE)
			artboard.canvas.set_eraser(20)


func _on_dynamics_btn(index):
	match index:
		0 : artboard.canvas.dynamics = Dynamics.NONE
		1 : artboard.canvas.dynamics = Dynamics.PRESSURE
		2 : artboard.canvas.dynamics = Dynamics.VELOCITY
