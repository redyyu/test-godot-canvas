class_name GizmoSizer extends Node2D

signal hovered(gizmo)
signal pressed(gizmo)
signal changed(rect, gizmo)
signal applied(rect)


var zoom_ratio := 1.0:
	set(val):
		zoom_ratio = val
		for gizmo in gizmos:
			gizmo.zoom_ratio = zoom_ratio

var bound_rect := Rect2i(Vector2i.ZERO, Vector2i.ZERO) :
	set(val):
		bound_rect = val
		for gizmo in gizmos:
			set_gizmo_place(gizmo)
var gizmos :Array[Gizmo] = []

var pressed_gizmo :Variant = null
var has_pressed :bool :
	get: return pressed_gizmo is Gizmo


func _ready():
	visible = false
	gizmos.append(Gizmo.new(Gizmo.TOP_LEFT))
	gizmos.append(Gizmo.new(Gizmo.TOP_CENTER))
	gizmos.append(Gizmo.new(Gizmo.TOP_RIGHT))
	gizmos.append(Gizmo.new(Gizmo.MIDDLE_RIGHT))
	gizmos.append(Gizmo.new(Gizmo.BOTTOM_RIGHT))
	gizmos.append(Gizmo.new(Gizmo.BOTTOM_CENTER))
	gizmos.append(Gizmo.new(Gizmo.BOTTOM_LEFT))
	gizmos.append(Gizmo.new(Gizmo.MIDDLE_LEFT))
	for gizmo in gizmos:
		gizmo.hovered.connect(_on_gizmo_hovered)
		gizmo.pressed.connect(_on_gizmo_pressed)
		add_child(gizmo)


func launch(rect :Rect2i):
	bound_rect = rect
	visible = true


func dismiss():
	visible = false


func move_to(gizmo:Gizmo, pos :Vector2i):
	match gizmo.pivot:
		Gizmo.TOP_LEFT: 
			if pos.x < bound_rect.end.x and pos.y < bound_rect.end.y:
				bound_rect.size = bound_rect.end - pos
				bound_rect.position = pos
		Gizmo.TOP_CENTER: 
			if pos.y < bound_rect.end.y:
				bound_rect.size.y = bound_rect.end.y - pos.y
				bound_rect.position.y = pos.y
		Gizmo.TOP_RIGHT: 
			if pos.x > bound_rect.position.x and pos.y < bound_rect.end.y:
				bound_rect.size.x = pos.x - bound_rect.position.x
				bound_rect.size.y = bound_rect.end.y - pos.y
				bound_rect.position.y = pos.y
		Gizmo.MIDDLE_RIGHT:
			if pos.x > bound_rect.position.x:
				bound_rect.size.x = pos.x - bound_rect.position.x
		Gizmo.BOTTOM_RIGHT:
			if pos.x > bound_rect.position.x and pos.y > bound_rect.position.y:
				bound_rect.size = pos - bound_rect.position
		Gizmo.BOTTOM_CENTER:
			if pos.y > bound_rect.position.y:
				bound_rect.size.y = pos.y - bound_rect.position.y
		Gizmo.BOTTOM_LEFT:
			if pos.x < bound_rect.end.x and pos.y > bound_rect.position.y:
				bound_rect.size.y = pos.y - bound_rect.position.y
				bound_rect.size.x = bound_rect.end.x - pos.x
				bound_rect.position.x = pos.x
		Gizmo.MIDDLE_LEFT:
			if pos.x < bound_rect.end.x:
				bound_rect.size.x = bound_rect.end.x - pos.x
				bound_rect.position.x = pos.x
	
	for gzm in gizmos:
		set_gizmo_place(gzm)
		
	changed.emit(bound_rect, gizmo)


func set_gizmo_place(gizmo):
	var gpos = bound_rect.position
	var gsize = bound_rect.size
	
	match gizmo.pivot:
		Gizmo.TOP_LEFT: 
			gizmo.position = Vector2(gpos) + Vector2.ZERO
		Gizmo.TOP_CENTER: 
			gizmo.position = Vector2(gpos) + Vector2(gsize.x / 2, 0)
		Gizmo.TOP_RIGHT: 
			gizmo.position = Vector2(gpos) + Vector2(gsize.x, 0)
		Gizmo.MIDDLE_RIGHT:
			gizmo.position = Vector2(gpos) + Vector2(gsize.x, gsize.y / 2)
		Gizmo.BOTTOM_RIGHT:
			gizmo.position = Vector2(gpos) + Vector2(gsize.x, gsize.y)
		Gizmo.BOTTOM_CENTER:
			gizmo.position = Vector2(gpos) + Vector2(gsize.x / 2, gsize.y)
		Gizmo.BOTTOM_LEFT:
			gizmo.position = Vector2(gpos) + Vector2(0, gsize.y)
		Gizmo.MIDDLE_LEFT:
			gizmo.position = Vector2(gpos) + Vector2(0, gsize.y / 2)


func _input(event :InputEvent):
	# TODO: the way handle the events might not support touch / tablet. 
	# since I have no device to try. leave it for now.

	if not visible:
		return

	if event is InputEventMouseMotion and has_pressed:
		move_to(pressed_gizmo, get_global_mouse_position())
		# it is in a sub viewport, and without any influence with layout.
		# so `get_global_mouse_position()` should work.
	elif event is InputEventMouseButton and event.double_click:
		if bound_rect.has_point(get_global_mouse_position()):
			applied.emit(bound_rect)


func _on_gizmo_hovered(gizmo):
	hovered.emit(gizmo)
	

func _on_gizmo_pressed(gizmo):
	hovered.emit(gizmo)
	pressed_gizmo = gizmo


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

class Gizmo extends Node2D :
	
	signal hovered(gizmo)
	signal pressed(gizmo)

	signal moving(gizmo, area)

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

	var pivot := TOP_LEFT

	var color := Color(0.2, 0.2, 0.2, 1)
	var bgcolor := Color.WHITE

	var default_size := Vector2(10, 10)

	var size :Vector2 :
		get: return default_size / zoom_ratio
	var rectangle :Rect2 :
		get: return Rect2(- pivot_offset, size)
	var pivot_offset :Vector2:
		get = _get_pivot_pos

	var zoom_ratio := 1.0:
		set(val):
			zoom_ratio = val
			queue_redraw()

	var cursor := Control.CURSOR_ARROW

	var is_hover := false
	var is_pressed := false


	func _init(_pivot):
		pivot = _pivot
		
		match pivot:
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


	func _get_pivot_pos():
		match pivot:
			TOP_LEFT:
				return Vector2(size.x, size.y)
			TOP_CENTER:
				return Vector2(size.x/2, size.y)
			TOP_RIGHT:
				return Vector2(0, size.y)
			MIDDLE_RIGHT:
				return Vector2(0, size.y/2)
			BOTTOM_RIGHT:
				return Vector2(0, 0)
			BOTTOM_CENTER:
				return Vector2(size.x/2, 0)
			BOTTOM_LEFT:
				return Vector2(size.x, 0)
			MIDDLE_LEFT:
				return Vector2(size.x, size.y/2)
			_:
				return Vector2.ZERO

	func _draw():
		if not visible:
			return
		draw_rect(rectangle, color if is_hover else bgcolor)
		draw_rect(rectangle, color, false, 1 / zoom_ratio)


	func _input(event :InputEvent):
		# TODO: the way handle the events might not support touch / tablet. 
		# since I have no device to try. leave it for now.
		
		if event is InputEventMouse:
			var pos = get_local_mouse_position()
			var hover = rectangle.has_point(pos)
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
						pressed.emit(null)
			else:
				if is_hover:
					is_hover = false
					hovered.emit(null)
					queue_redraw()  # redraw hover effect
				if is_pressed and event is InputEventMouseButton:
					# for release outside
					is_pressed = false
					pressed.emit(null)
