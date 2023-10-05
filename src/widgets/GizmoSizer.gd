class_name GizmoSizer extends Node2D

signal gizmo_hover_changed(gizmo, status)
signal gizmo_press_changed(gizmo, status)
signal changed(rect)
signal drag_started
signal drag_ended


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

var zoom_ratio := 1.0 :
	set(val):
		zoom_ratio = val
		for gizmo in gizmos:
			gizmo.zoom_ratio = zoom_ratio

var bound_rect := Rect2i(Vector2i.ZERO, Vector2i.ZERO) :
	set = update_bound_rect

var gizmos :Array[Gizmo] = []

var pressed_gizmo :Variant = null
var last_position :Variant = null # prevent same with mouse pos from beginning.

var is_dragging := false :
	set(val):
		is_dragging = val
		if visible: # emit event when showing up.
			if is_dragging:
				drag_started.emit()
			else:
				drag_ended.emit()
	get: return is_dragging and visible

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
		gizmo.hover_changed.connect(_on_gizmo_hover_changed)
		gizmo.press_changed.connect(_on_gizmo_press_changed)
		add_child(gizmo)


func attach(rect :Rect2i, auto_hire := false):
	if rect.has_area():
		bound_rect = rect
		if auto_hire:
			hire()


func update_bound_rect(val :Rect2i):
	bound_rect = val
	if bound_rect.has_area():
		for gizmo in gizmos:
			set_gizmo_place(gizmo)


func hire():
	if not visible:
		visible = true
	

func dismiss():
	if visible:
		visible = false
		drag_offset = Vector2i.ZERO
		pressed_gizmo = null
		last_position = null
		is_dragging = false


func drag_to(pos :Vector2i):
	if last_position == pos:
		return
	# use to prevent running while already stop.
	last_position = pos
	
	pos -= drag_offset  # DO calculate drag_offset just pressed, NOT here.

	# convert to local pos from the rect zero pos. 
	# DO NOT use get_local_mouse_position, because bound_rect is not zero pos.
	var pos_corners := []
	pos_corners.append({ # top left corner
		'position': pos,
		'offset': Vector2i.ZERO,
	})
	pos_corners.append({ # top right corner
		'position': Vector2i(pos.x + bound_rect.size.x, pos.y),
		'offset': Vector2i(bound_rect.size.x, 0)
	})
	pos_corners.append({ # bottom right corner
		'position': pos + bound_rect.size,
		'offset': bound_rect.size
	})
	pos_corners.append({ # bottom left corner
		'position': Vector2i(pos.x, pos.y + bound_rect.size.y),
		'offset': Vector2i(0, bound_rect.size.y)
	})
	
	var snap_pos = null
	var last_weight := 0
	for corner in pos_corners:
		var _weight := 0
		snap_pos = get_snapping_weight.call(corner['position'])
		if snap_pos is Vector3i or snap_pos is Vector3:
			_weight = snap_pos.z
			snap_pos = Vector2i(snap_pos.x, snap_pos.y)
		if _weight > last_weight:
			last_weight = _weight
			pos = Vector2i(snap_pos) - corner['offset']
	
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


func _input(event :InputEvent):
	# TODO: the way handle the events might not support touch / tablet. 
	# since I have no device to try. leave it for now.

	if not visible:
		return

	if event is InputEventMouseMotion:
		var pos := get_local_mouse_position()
		if pressed_gizmo:
			if is_dragging:  # prevent the dragging zone is hit.
				is_dragging = false
			var snap_pos = get_snapping_weight.call(pos)
			if snap_pos is Vector3i or snap_pos is Vector3:
				snap_pos = Vector2i(snap_pos.x, snap_pos.y)
			scale_to(pressed_gizmo, snap_pos)
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
			is_dragging = event.pressed
			if is_dragging: 
				drag_offset = Vector2i(pos) - bound_rect.position
		elif is_dragging:
			is_dragging = false



func _on_gizmo_hover_changed(gizmo, status):
	gizmo_hover_changed.emit(gizmo, status)
	

func _on_gizmo_press_changed(gizmo, status):
	gizmo_press_changed.emit(gizmo, status)
	pressed_gizmo = gizmo if status else null


var get_snapping_weight = func(pos) -> Vector3i:
	return Vector3i(pos.x, pos.y, -1)


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
	
	signal hover_changed(gizmo, status)
	signal press_changed(gizmo, status)

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

	var is_hover := false :
		set(val):
			is_hover = val
			hover_changed.emit(self, is_hover)

	var is_pressed := false:
		set(val):
			is_pressed = val
			press_changed.emit(self, is_pressed)


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
					queue_redraw()  # redraw hover effect
				if event is InputEventMouseButton:
					is_pressed = event.pressed
					queue_redraw()
			else:
				if is_hover:
					is_hover = false
					queue_redraw()  # redraw hover effect
				if is_pressed and event is InputEventMouseButton:
					# for release outside
					is_pressed = false
					queue_redraw()
