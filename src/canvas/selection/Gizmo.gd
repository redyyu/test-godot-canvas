class_name Gizmo extends Node2D
	
signal hovered(gizmo)
signal unhovered(gizmo)
signal pressed(gizmo)
signal unpressed(gizmo)

enum {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	MIDDLE_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_CENTER,
	BOTTOM_LEFT,
	MIDDLE_LEFT,
}

var direction := TOP_LEFT

var gizmo_color := Color(0.2, 0.2, 0.2, 1)
var gizmo_bgcolor := Color.WHITE

var default_size := Vector2(10, 10)

var gizmo_size :Vector2 :
	get: return default_size / zoom_ratio
var gizmo_rect :Rect2 :
	get: return Rect2(- pivot_pos, gizmo_size)
var pivot_pos :Vector2:
	get = _get_pivot_pos
#var toucher := ColorRect.new()
var zoom_ratio := 1.0:
	set(val):
		zoom_ratio = val
#		toucher.size = gizmo_size
		queue_redraw()

var cursor := Control.CURSOR_ARROW

var is_hover := false
var is_pressed := false


func _init(_direction):
	visible = false
	direction = _direction
#	toucher.size = gizmo_size
#	toucher.color = Color(1, 0, 0, 0.3)
#	toucher.mouse_entered.connect(_on_mouse_over)
#	add_child(toucher)
	
	match direction:
		TOP_LEFT:
			cursor = Control.CURSOR_FDIAGSIZE
		TOP_CENTER:
			cursor = Control.CURSOR_VSIZE
		TOP_RIGHT:
			cursor = Control.CURSOR_BDIAGSIZE
		MIDDLE_RIGHT:
			cursor = Control.CURSOR_HSIZE
		BOTTOM_RIGHT:
			cursor = Control.CURSOR_FDIAGSIZE
		BOTTOM_CENTER:
			cursor = Control.CURSOR_VSIZE
		BOTTOM_LEFT:
			cursor = Control.CURSOR_BDIAGSIZE
		MIDDLE_LEFT:
			cursor = Control.CURSOR_HSIZE
		_:
			cursor = Control.CURSOR_POINTING_HAND


func dismiss():
	visible = false
	
func place(rect :Rect2i):
	if not rect:
		return

	visible = true
	
	var gpos = rect.position
	var gsize = rect.size
	
	match direction:
		TOP_LEFT: 
			position = Vector2(gpos) + Vector2.ZERO
		TOP_CENTER: 
			position = Vector2(gpos) + Vector2(gsize.x / 2, 0)
		TOP_RIGHT: 
			position = Vector2(gpos) + Vector2(gsize.x, 0)
		MIDDLE_RIGHT:
			position = Vector2(gpos) + Vector2(gsize.x, gsize.y / 2)
		BOTTOM_RIGHT:
			position = Vector2(gpos) + Vector2(gsize.x, gsize.y)
		BOTTOM_CENTER:
			position = Vector2(gpos) + Vector2(gsize.x / 2, gsize.y)
		BOTTOM_LEFT:
			position = Vector2(gpos) + Vector2(0, gsize.y)
		MIDDLE_LEFT:
			position = Vector2(gpos) + Vector2(0, gsize.y / 2)

func _get_pivot_pos():
	match direction:
		TOP_LEFT:
			return Vector2(gizmo_size.x, gizmo_size.y)
		TOP_CENTER:
			return Vector2(gizmo_size.x/2, gizmo_size.y)
		TOP_RIGHT:
			return Vector2(0, gizmo_size.y)
		MIDDLE_RIGHT:
			return Vector2(0, gizmo_size.y/2)
		BOTTOM_RIGHT:
			return Vector2(0, 0)
		BOTTOM_CENTER:
			return Vector2(gizmo_size.x/2, 0)
		BOTTOM_LEFT:
			return Vector2(gizmo_size.x, 0)
		MIDDLE_LEFT:
			return Vector2(gizmo_size.x, gizmo_size.y/2)
		_:
			return Vector2.ZERO


# Use custom draw_rect and input event to replace
# what Control (such as ColorRect) should do,
# When `GUI / Snap Controls to Pixels` on Viewport is open.
# will cause a tiny teeny position jumpping, which is unexcepted.
# because the control always try to snap nearest pixel.
# it might happen on any `Control`, have not test on others.
# the Gizmo class is already done when I figure it out,
# so leave it NOT Control for now.
# also seems not much easier to do when use control, 
# still need check the press or not, unless use button.
# but button have much work to do with the style.
# anyway, leave it Node2D for now.
#
# ex., try give the toucher a color and zoom in the camera.
# ```
# toucher = ColorRect.new()
# toucher.size = gizmo_size * 4
# toucher.position = - toucher.size / 2
# print('position ', toucher.position, '/ size /2 ', toucher.size/2)
# ```


func _draw():
	draw_rect(gizmo_rect, gizmo_color if is_hover else gizmo_bgcolor)
	draw_rect(gizmo_rect, gizmo_color, false, 1 / zoom_ratio)


func _input(event :InputEvent):
	# TODO: the way handle the events might not support touch / tablet. 
	# since I have no device to try. leave it for now.
	
	if event is InputEventMouse:
		var pos = get_local_mouse_position()
		var hover = gizmo_rect.has_point(pos)
		if hover:
			if not is_hover:
				is_hover = true
				hovered.emit(self)
				queue_redraw()  # redraw hover effect
			if event is InputEventMouseButton:
				is_pressed = event.pressed
				if is_pressed:
					pressed.emit(self)
				else:
					unpressed.emit(self)
		else:
			if is_hover:
				is_hover = false
				unhovered.emit(self)
				queue_redraw()  # redraw hover effect
			if is_pressed and event is InputEventMouseButton:
				# for release outside
				is_pressed = false
				unpressed.emit(self)
