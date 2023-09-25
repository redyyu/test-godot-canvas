extends Control

var current_color := Color.WHITE

@onready var artboard :SubViewportContainer = $Artboard

@onready var btn_1 = $BtnNone
@onready var btn_2 = $BtnPan
@onready var btn_3 = $BtnZoom
@onready var btn_4 = $BtnDraw
@onready var btn_5 = $BtnErase


func _ready():
	g.current_project = Project.new(Vector2i(400, 300))
	
	artboard.load_project(g.current_project)
	
	btn_1.pressed.connect(_on_btn_pressed.bind(btn_1))
	btn_2.pressed.connect(_on_btn_pressed.bind(btn_2))
	btn_3.pressed.connect(_on_btn_pressed.bind(btn_3))
	btn_4.pressed.connect(_on_btn_pressed.bind(btn_4))
	btn_5.pressed.connect(_on_btn_pressed.bind(btn_5))
	

func _on_btn_pressed(btn):
	print(btn.name)
	match btn.name:
		'BtnNone':
			artboard.activate_state(ArtboardState.NONE)
		'BtnPan':
			artboard.activate_state(ArtboardState.DRAG)
		'BtnZoom':
			artboard.activate_state(ArtboardState.ZOOM)
		'BtnDraw':
			artboard.activate_state(ArtboardState.DRAW)
			if current_color == Color.RED:
				current_color = Color.GREEN
			else:
				current_color = Color.RED
			artboard.canvas.set_drawer(10, current_color)
			btn.modulate = current_color
		'BtnErase':
			artboard.activate_state(ArtboardState.ERASE)
			artboard.canvas.set_drawer(10)

