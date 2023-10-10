class_name TransformPanel extends Panel

var operator :Variant
var as_force_editable := false

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
	
	input_width.max_value = 12000
	input_height.max_value = 12000
	input_x.max_value = 12000
	input_y.max_value = 12000
	
	set_editable(false)
	

func set_transform(rect :Rect2i, status := false):
	if not rect.has_area():
		status = false
	input_x.set_value_no_signal(rect.position.x)
	input_y.set_value_no_signal(rect.position.y)
	input_width.set_value_no_signal(rect.size.x)
	input_height.set_value_no_signal(rect.size.y)
	set_editable(status)


func set_editable(status):
	if as_force_editable:
		status = true
	input_x.editable = status
	input_y.editable = status
	input_width.editable = status
	input_height.editable = status
	opt_pivot.set_process_input(status)


func _on_input_size_updated(_val):
	if operator:
		var width = max(input_width.value, 1)
		var height = max(input_height.value, 1)
		operator.resize_to(Vector2i(width, height))


func _on_input_pos_updated(_val):
	if operator:
		operator.move_to(Vector2i(input_x.value, input_y.value))


func _on_pivot_updated(val):
	if operator:
		operator.set_pivot(val)


func _on_transform_updated(rect :Rect2i, rel_pos :Vector2i, status := true):
	rect.position = rel_pos
	set_transform(rect, status)


func _on_transform_canceled(rect :Rect2i, rel_pos :Vector2i):
	rect.position = rel_pos
	set_transform(rect, false)


func subscribe(new_operator, use_force_editable := false):
	unsubscribe()
	as_force_editable = use_force_editable
	if as_force_editable:
		set_editable(true)
	operator = new_operator
	if operator:
		operator.updated.connect(_on_transform_updated)
		operator.canceled.connect(_on_transform_canceled)
		operator.set_pivot(opt_pivot.pivot_value)


func unsubscribe():
	if operator:
		if operator.updated.is_connected(_on_transform_updated):
			operator.updated.disconnect(_on_transform_updated)
		if operator.canceled.is_connected(_on_transform_canceled):
			operator.canceled.disconnect(_on_transform_canceled)
	set_transform(Rect2i(), false)
	operator = null
