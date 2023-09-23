extends Control

@onready var artboard :SubViewportContainer = $Artboard

@onready var btn_1 = $Button
@onready var btn_2 = $Button2
@onready var btn_3 = $Button3


func _ready():
	g.current_project = Project.new(Vector2i(400, 300))
	
	artboard.load_project(g.current_project)
	
	btn_1.pressed.connect(_on_btn_pressed.bind(btn_1))
	btn_2.pressed.connect(_on_btn_pressed.bind(btn_2))
	btn_3.pressed.connect(_on_btn_pressed.bind(btn_3))
	

func _on_btn_pressed(btn):
	match btn.name:
		'Button':
			artboard.activate_state(Artboard.StateType.DRAG)
		'Button2':
			artboard.activate_state(Artboard.StateType.ZOOM)
		'Button3':
			artboard.activate_state(Artboard.StateType.NONE)

