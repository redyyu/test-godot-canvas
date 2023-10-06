class_name TransformPanel extends Panel

signal size_updated(to_size)
signal position_updated(to_pos)
signal pivot_updated(to_pivot)


var block_input := false

var current_rect :Rect2i

@onready var opt_pivot := %OptPivot
@onready var input_width := %InputWidth
@onready var input_height := %InputHeight
@onready var input_x := %InputPosX
@onready var input_y := %InputPosY


func _ready():
	input_width.value_changed.connect(_on_input_size_updated)
	input_height.value_changed.connect(_on_input_size_updated)
	input_x.value_changed.connect(_on_input_pos_updated)
	input_y.value_changed.connect(_on_input_pos_updated)
	opt_pivot.pivot_updated.connect(_on_pivot_updated)
	

func set_rect(rect :Rect2i, use_editable := false):
	current_rect = rect
	
	block_input = true
	input_x.value = rect.position.x
	input_y.value = rect.position.y
	input_width.value = rect.size.x
	input_height.value = rect.size.y
	if not rect.has_area():
		use_editable = false
	input_x.editable = use_editable
	input_y.editable = use_editable
	input_width.editable = use_editable
	input_height.editable = use_editable
	block_input = false
	

func _on_input_size_updated(_val):	
	if block_input:
		return
	size_updated.emit(Vector2i(input_width.value, input_height.value))


func _on_input_pos_updated(_val):
	if block_input:
		return
	position_updated.emit(Vector2i(input_x.value, input_y.value))


func _on_pivot_updated(val):
	pivot_updated.emit(val)

