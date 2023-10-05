class_name TransformPanel extends Panel

signal size_changed(to_size)
signal position_changed(to_pos)
signal pivot_changed(to_pivot)


var block_input := false

var current_rect :Rect2i:
	set(val):
		current_rect = val
		update_info(current_rect)

@onready var opt_pivot := %OptPivot
@onready var input_width := %InputWidth
@onready var input_height := %InputHeight
@onready var input_x := %InputPosX
@onready var input_y := %InputPosY


func _ready():
	input_width.value_changed.connect(_on_input_size_changed)
	input_height.value_changed.connect(_on_input_size_changed)
	input_x.value_changed.connect(_on_input_pos_changed)
	input_y.value_changed.connect(_on_input_pos_changed)
	opt_pivot.pivot_changed.connect(_on_pivot_changed)


func update_info(rect):
	block_input = true
	input_x.value = rect.x
	input_y.value = rect.y
	input_width.value = rect.size.x
	input_height.value = rect.size.y
	if rect.has_area():
		input_x.editable = true
		input_y.editable = true
		input_width.editable = true
		input_height.editable = true
	else:
		input_x.editable = false
		input_y.editable = false
		input_width.editable = false
		input_height.editable = false
	block_input = false
	

func _on_input_size_changed(_val):	
	if block_input:
		return
	size_changed.emit(Vector2i(input_width.value, input_height.value))


func _on_input_pos_changed(_val):
	if block_input:
		return
	position_changed.emit(Vector2i(input_x.value, input_y.value))


func _on_pivot_changed(val):
	pivot_changed.emit(val)

