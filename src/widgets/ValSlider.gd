@tool
extends ProgressBar

class_name ValSlider

enum {
	NORMAL,
	HELD,
	SLIDING,
	TYPING,
}

var state = NORMAL
var mouse_start_pos :Vector2 = Vector2.ZERO
var last_value: float = 0
var last_ratio: float = 0.0
var overlayer :ColorRect = ColorRect.new()
var valueLineEdit :LineEdit
var slided_pressed :bool = false
var btn_pressed = false

var valueSpinBox :SpinBox = SpinBox.new()


@export var slide_by_step :bool = false
@export var slide_pressure :float = 1.0

@export var hidden_text :bool = false :
	set(val):
		hidden_text = val
		if hidden_text:
			valueSpinBox.hide()
		else:
			valueSpinBox.show()

@export var text_alignment :HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER:
	set(val): 
		text_alignment = val
		valueSpinBox.alignment = text_alignment
		
@export var prefix :String = '' :
	set(val):
		prefix = val
		valueSpinBox.prefix = prefix
		
@export var suffix :String = '' :
	set(val):
		suffix = val
		valueSpinBox.suffix = suffix
		
@export var spin_icon :Texture2D :
	set(val):
		spin_icon = val
		if spin_icon:
			valueSpinBox.add_theme_icon_override('updown', spin_icon)
		else:
			valueSpinBox.remove_theme_icon_override('updown')



func _init():
	show_percentage = false
	if custom_minimum_size.y < 30:
		custom_minimum_size.y = 30


func _ready():
	# spin box
	valueSpinBox.alignment = text_alignment
	valueSpinBox.prefix = prefix
	valueSpinBox.suffix = suffix
	valueSpinBox.min_value = min_value
	valueSpinBox.max_value = max_value
	valueSpinBox.value = value
	valueSpinBox.step = step
	valueSpinBox.exp_edit = exp_edit
	valueSpinBox.rounded = rounded
	valueSpinBox.allow_greater = allow_greater
	valueSpinBox.allow_lesser = allow_lesser
#	valueSpinBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	valueSpinBox.value_changed.connect(_on_spin_value_changed)
	valueSpinBox.set_anchors_preset(Control.PRESET_FULL_RECT)
	if spin_icon:
		valueSpinBox.add_theme_icon_override('updown', spin_icon)
	add_child(valueSpinBox)

	# for line edit of the spin box
	override_lineedit_stylebox(valueSpinBox)
	
	valueLineEdit = valueSpinBox.get_line_edit()
	valueLineEdit.selecting_enabled = false
	valueLineEdit.gui_input.connect(_on_line_edit_gui_input)
	valueLineEdit.focus_exited.connect(_on_line_edit_focus_exit)
	valueLineEdit.resized.connect(_on_line_edit_resized)
	
	overlayer.color = Color.TRANSPARENT
	overlayer.size = valueLineEdit.size
	overlayer.gui_input.connect(_on_overlayer_gui_input)
	overlayer.mouse_exited.connect(_on_overlayer_mouseout)
	add_child(overlayer)
	
	if hidden_text:
		valueSpinBox.hide()
		
	value_changed.connect(_on_value_changed)
	changed.connect(_on_changed)


func override_lineedit_stylebox(spinbox):
	var line_edit :LineEdit = spinbox.get_line_edit()
	for style_key in ['normal', 'focus', 'read_only']:
		var stylebox = line_edit.get_theme_stylebox(style_key).duplicate()
	#	_stylebox_normal.draw_center = false
		stylebox.bg_color = Color.TRANSPARENT
		stylebox.border_width_bottom = 0
		stylebox.border_width_top = 0
		stylebox.border_width_left = 0
		stylebox.border_width_right = 0
		line_edit.add_theme_stylebox_override(style_key, stylebox)
	line_edit.mouse_default_cursor_shape = Control.CURSOR_ARROW


func change_progress():
	var _distanc :float
	var _delta :float
	
	match fill_mode:
		FILL_BEGIN_TO_END:
			_delta = get_global_mouse_position().x - mouse_start_pos.x
			_distanc = size.x
		FILL_END_TO_BEGIN:
			_delta = mouse_start_pos.x - get_global_mouse_position().x
			_distanc = size.x
		FILL_TOP_TO_BOTTOM:
			_delta = get_global_mouse_position().y - mouse_start_pos.y
			_distanc = size.y
		FILL_BOTTOM_TO_TOP:
			_delta = mouse_start_pos.y - get_global_mouse_position().y
			_distanc = size.y
	
	if slide_by_step:
		value = last_value + (_delta * slide_pressure) * step
	else:
		ratio = last_ratio + _delta / _distanc
	

func _on_overlayer_gui_input(event: InputEvent):
	if (event is InputEventMouseButton):
		btn_pressed = event.pressed
	match state:
		NORMAL:
			if (event is InputEventMouseButton and btn_pressed and
				event.button_index == MOUSE_BUTTON_LEFT):
				state = HELD
				mouse_start_pos = get_global_mouse_position()
				last_value = value
				last_ratio = ratio
		HELD:
			if (event is InputEventMouseButton and btn_pressed and
				event.button_index == MOUSE_BUTTON_LEFT):
				state = TYPING
				overlayer.hide()
				valueSpinBox.get_line_edit().grab_focus()
				valueLineEdit.selecting_enabled = true
			elif event is InputEventMouseMotion and btn_pressed:
				if mouse_start_pos.distance_to(get_global_mouse_position()) > 2:
					state = SLIDING
		SLIDING:
			if (event is InputEventMouseButton and not btn_pressed and
				event.button_index == MOUSE_BUTTON_LEFT):
				state = NORMAL
			elif event is InputEventMouseMotion and btn_pressed:
				change_progress()


func _on_overlayer_mouseout():
	if state == HELD:
		state = NORMAL


func _on_changed():
	valueSpinBox.min_value = min_value
	valueSpinBox.max_value = max_value
	valueSpinBox.value = value
	valueSpinBox.step = step
	valueSpinBox.exp_edit = exp_edit
	valueSpinBox.rounded = rounded
	valueSpinBox.allow_greater = allow_greater
	valueSpinBox.allow_lesser = allow_lesser


func _on_value_changed(val):
	valueSpinBox.value = val


func _on_spin_value_changed(val):
	value = val


func _on_line_edit_resized():
	overlayer.size = valueLineEdit.size


func _on_line_edit_gui_input(event: InputEvent):
	match state:
		NORMAL:
			if event is InputEventMouseButton:
				overlayer.hide()
				state = TYPING
		TYPING:
			if event is InputEventKey and event.keycode == KEY_ESCAPE:
				valueLineEdit.release_focus()


func _on_line_edit_focus_exit():
	state = NORMAL
	overlayer.show()
	valueLineEdit.selecting_enabled = false
