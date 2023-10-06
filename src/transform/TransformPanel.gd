class_name TransformPanel extends Panel

signal size_updated(to_size)
signal position_updated(to_pos)
signal pivot_updated(to_pivot)

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
	
	input_x.editable = false
	input_y.editable = false
	input_width.editable = false
	input_height.editable = false
	input_width.min_value = 1
	input_height.min_value = 1
	input_width.max_value = 12000
	input_height.max_value = 12000
	input_x.max_value = 12000
	input_y.max_value = 12000
	

func set_rect(rect :Rect2i, use_editable := false):
	input_x.set_value_no_signal(rect.position.x)
	input_y.set_value_no_signal(rect.position.y)
	input_width.set_value_no_signal(rect.size.x)
	input_height.set_value_no_signal(rect.size.y)
	if not rect.has_area():
		use_editable = false
	input_x.editable = use_editable
	input_y.editable = use_editable
	input_width.editable = use_editable
	input_height.editable = use_editable
	

func _on_input_size_updated(_val):
	size_updated.emit(Vector2i(input_width.value, input_height.value))


func _on_input_pos_updated(_val):
	position_updated.emit(Vector2i(input_x.value, input_y.value))


func _on_pivot_updated(val):
	pivot_updated.emit(val)

