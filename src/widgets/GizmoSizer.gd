class_name GizmoSizer extends Node2D

signal hovered(gizmo)
signal pressed(gizmo)
signal changed(rect)
signal applied(rect)
signal dragged(dragging)
signal activated(activated)

@export var gizmo_color := Color(0.2, 0.2, 0.2, 1):
	set(val):
		gizmo_color = val
		for gizmo in gizmos:
			gizmo.color = gizmo_color
			
@export var gizmo_bgcolor := Color.WHITE :
	set(val):
		gizmo_bgcolor = val
		for gizmo in gizmos:
			gizmo.bgcolor = gizmo_bgcolor
			
@export var gizmo_line_width := 1.0:
	set(val):
		gizmo_line_width = val
		for gizmo in gizmos:
			gizmo.line_width = gizmo_line_width

@export var gizmo_size := Vector2(10, 10) :
	set(val):
		gizmo_size = val
		for gizmo in gizmos:
			gizmo.default_size = gizmo_size

var stored_color := gizmo_color
var stored_bgcolor := gizmo_bgcolor

var zoom_ratio := 1.0 :
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
var last_position :Variant = null # prevent same with mouse pos from beginning.


var is_dragging := false :
	set(val):
		is_dragging = val
		dragged.emit(is_dragging)
		
var is_activated := false :
	get: return is_activated or opt_auto_activate
	set(val):
		is_activated = val
		activated.emit(is_activated)
		activate_gizmos()

var opt_auto_activate := false :
	set(val):
		opt_auto_activate = val
		activated.emit(is_activated)
		activate_gizmos()

var drag_offset := Vector2i.ZERO


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
		gizmo.color = gizmo_color
		gizmo.bgcolor = gizmo_bgcolor
		gizmo.default_size = gizmo_size
		gizmo.line_width = gizmo_line_width
		gizmo.hovered.connect(_on_gizmo_hovered)
		gizmo.pressed.connect(_on_gizmo_pressed)
		add_child(gizmo)


func restore_colors():
	if stored_color != gizmo_color:
		gizmo_color = stored_color

	if stored_bgcolor != gizmo_bgcolor:
		gizmo_bgcolor = stored_bgcolor


func launch(rect :Rect2i):
	if rect.has_area():
		bound_rect = rect
		activate_gizmos()
		visible = true


func dismiss():
	visible = false


func drag_to(pos :Vector2i):
	if last_position == pos:
		return
	# use to prevent running while already stop.
	last_position = pos
	
	pos -= drag_offset  # DO calculate drag_offset just pressed, NOT here.

	# convert to local pos from the rect zero pos. 
	# DO NOT use get_local_mouse_position, because bound_rect is not zero pos.
	var pos_corners := []
	pos_corners.append({
		'position': pos,
		'offset': Vector2i.ZERO,
	})
	pos_corners.append({
		'position': Vector2i(pos.x + bound_rect.size.x, pos.y),
		'offset': Vector2i(bound_rect.size.x, 0)
	})
	pos_corners.append({
		'position': pos + bound_rect.size,
		'offset': bound_rect.size
	})
	pos_corners.append({
		'position': Vector2i(pos.x, pos.y + bound_rect.size.y),
		'offset': Vector2i(0, bound_rect.size.y)
	})
	
	var snap_pos = pos
	for corner in pos_corners:
		snap_pos = get_snapping.call(corner['position'])
		if snap_pos != corner['position']:
			pos = snap_pos - corner['offset']
			break
	
	bound_rect.position = pos
	
	for gzm in gizmos:
		set_gizmo_place(gzm)
	
	changed.emit(bound_rect)


func scale_to(gizmo:Gizmo, pos :Vector2i):
	if last_position == pos:
		return
	# use to prevent running while already stop.
	last_position = pos
		
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

	changed.emit(bound_rect)


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


func activate_gizmos():
	for gizmo in gizmos:
		gizmo.visible = is_activated


func has_gizmo_pressed() -> bool:
	return pressed_gizmo is Gizmo


func _input(event :InputEvent):
	# TODO: the way handle the events might not support touch / tablet. 
	# since I have no device to try. leave it for now.

	if not visible:
		return

	if event is InputEventMouseMotion:
		var pos := get_local_mouse_position()
		if has_gizmo_pressed():
			if is_dragging:  # prevent the dragging zone is hit.
				is_dragging = false
			scale_to(pressed_gizmo, get_snapping.call(pos))
			# it is in a sub viewport, and without any influence with layout.
			# so `get_global_mouse_position()` should work.
		elif is_dragging:
			drag_to(pos)
			# DO NOT check `bound_rect.has_point(pos)` here,
			# that will got bad experience when hit a snap point.
			# when hit a snap point and move faster, it will unexcpet stop.

	elif event is InputEventMouseButton:
		var pos := get_local_mouse_position()
		# its in subviewport local mouse position should be work.
		if bound_rect.has_point(pos):
			if event.double_click:
				applied.emit(bound_rect)
				is_activated = false
			else:
				if is_activated:
					is_dragging = event.pressed
					if is_dragging: 
						drag_offset = Vector2i(pos) - bound_rect.position
				elif event.pressed: 
					is_activated = true
		else:
			if event.pressed and not has_gizmo_pressed():
				is_activated = false

			if is_dragging:
				is_dragging = false



func _on_gizmo_hovered(gizmo):
	hovered.emit(gizmo)
	

func _on_gizmo_pressed(gizmo):
	hovered.emit(gizmo)
	pressed_gizmo = gizmo


var get_snapping = func(pos) -> Vector2i:
	return pos


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

	var color := Color(0.2, 0.2, 0.2, 1) :
		set(val):
			color = val
			queue_redraw()
			
	var bgcolor := Color.WHITE :
		set(val):
			bgcolor = val
			queue_redraw()
			
	var line_width := 1.0 :
		set(val):
			line_width = val
			queue_redraw()

	var default_size := Vector2(10, 10) :
		set(val):
			default_size = val
			queue_redraw()

	var size :Vector2 :
		get: return default_size / zoom_ratio
		
	var rectangle :Rect2 :
		get: return Rect2(- pivot_offset, size)
		
	var touch :Rect2 :
		get: return Rect2(-size, size * 2)
		
	var pivot_offset :Vector2:
		get = _get_pivot_pos

	var zoom_ratio := 1.0 :
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
		draw_rect(rectangle, color if is_hover or is_pressed else bgcolor)
		draw_rect(rectangle, color, false, line_width / zoom_ratio)


	func _input(event :InputEvent):
		# TODO: the way handle the events might not support touch / tablet. 
		# since I have no device to try. leave it for now.
		
		if event is InputEventMouse:
			var pos = get_local_mouse_position()
			var hover = touch.has_point(pos)
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
					queue_redraw()
			else:
				if is_hover:
					is_hover = false
					hovered.emit(null)
					queue_redraw()  # redraw hover effect
				if is_pressed and event is InputEventMouseButton:
					# for release outside
					is_pressed = false
					pressed.emit(null)
					queue_redraw()
