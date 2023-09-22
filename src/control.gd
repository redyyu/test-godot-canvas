extends Control

@onready var artboard :SubViewportContainer = $Artboard

@onready var btn_1 = $Button
@onready var btn_2 = $Button2


func _ready():
	g.current_project = Project.new(Vector2i(400, 300))
	artboard.load_project(g.current_project)
	
	btn_1.pressed.connect(_on_btn1_pressed)
	btn_2.pressed.connect(_on_btn2_pressed)
	

func _on_btn1_pressed():
	print('darg')
	artboard.activate_state(Artboard.StateType.DRAG)
	

func _on_btn2_pressed():
	print('zoom')
	artboard.activate_state(Artboard.StateType.ZOOM)
