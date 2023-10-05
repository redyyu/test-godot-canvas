class_name PivotSelector extends Control

signal pivot_changed(pivot)

enum {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	MIDDLE_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_CENTER,
	BOTTOM_LEFT,
	MIDDLE_LEFT,
	CENTER,
}

var btngroup := ButtonGroup.new()
var buttons :Array[PivotButton] = []


func _ready():
	buttons.append(PivotButton.new(TOP_LEFT))
	buttons.append(PivotButton.new(TOP_CENTER))
	buttons.append(PivotButton.new(TOP_RIGHT))
	buttons.append(PivotButton.new(MIDDLE_RIGHT))
	buttons.append(PivotButton.new(BOTTOM_RIGHT))
	buttons.append(PivotButton.new(BOTTOM_CENTER))
	buttons.append(PivotButton.new(BOTTOM_LEFT))
	buttons.append(PivotButton.new(MIDDLE_LEFT))
	buttons.append(PivotButton.new(CENTER))
	
	for btn in buttons:
		btn.button_group = btngroup
	
	btngroup.pressed.connect(_on_pivot_pressd)
	resized.connect(_on_resized)


func place_button(btn):
	match btn.pivot:
		TOP_LEFT:
			btn.position = Vector2(size.x, size.y)
		TOP_CENTER:
			btn.position = Vector2(size.x/2, size.y)
		TOP_RIGHT:
			btn.position = Vector2(0, size.y)
		MIDDLE_RIGHT:
			btn.position = Vector2(0, size.y/2)
		BOTTOM_RIGHT:
			btn.position = Vector2(0, 0)
		BOTTOM_CENTER:
			btn.position = Vector2(size.x/2, 0)
		BOTTOM_LEFT:
			btn.position = Vector2(size.x, 0)
		MIDDLE_LEFT:
			btn.position = Vector2(size.x, size.y/2)
		CENTER:
			btn.position = Vector2.ZERO
	

func _on_pivot_pressd(btn):
	pivot_changed.emit(btn.pivot)


func _on_resized():
	queue_redraw()


func _draw():
	



class PivotButton extends Button:
	
	var pivot := PivotSelector.TOP_LEFT

	
	func _init(_pivot):
		pivot = _pivot
		size = Vector2i(12, 12)
		flat = true

	
	func _ready():
		toggle_mode = true
		action_mode = Button.ACTION_MODE_BUTTON_PRESS

