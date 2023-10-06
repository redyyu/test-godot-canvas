class_name GizmoSizer extends Node2D

signal gizmo_hover_updated(gizmo, status)
signal gizmo_press_updated(gizmo, status)
signal updated(rect)
signal drag_updated(status)


enum Pivot {
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
var pivot := Pivot.TOP_LEFT

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
	set(val):
		bound_rect = val
		for gizmo in gizmos:
			set_gizmo_place(gizmo)

var gizmos :Array[Gizmo] = []

var relative_position :Vector2i :  # with pivot, for display on panel
	get:
		var _offset = get_pivot_offset(bound_rect.size)
		return bound_rect.position + _offset

var pressed_gizmo :Variant = null
var last_position :Variant = null # prevent same with mouse pos from beginning.

var is_dragging := false :
	set(val):
		is_dragging = val
		if visible: # emit event when showing up.
			drag_updated.emit(is_dragging)
	get: return is_dragging and visible

var drag_offset := Vector2i.ZERO


func _ready():
	visible = false
	gizmos.append(Gizmo.new(Pivot.TOP_LEFT))
	gizmos.append(Gizmo.new(Pivot.TOP_CENTER))
	gizmos.append(Gizmo.new(Pivot.TOP_RIGHT))
	gizmos.append(Gizmo.new(Pivot.MIDDLE_RIGHT))
	gizmos.append(Gizmo.new(Pivot.BOTTOM_RIGHT))
	gizmos.append(Gizmo.new(Pivot.BOTTOM_CENTER))
	gizmos.append(Gizmo.new(Pivot.BOTTOM_LEFT))
	gizmos.append(Gizmo.new(Pivot.MIDDLE_LEFT))
	for gizmo in gizmos:
		gizmo.color = gizmo_color
		gizmo.bgcolor = gizmo_bgcolor
		gizmo.default_size = gizmo_size
		gizmo.line_width = gizmo_line_width
		gizmo.hover_updated.connect(_on_gizmo_hover_updated)
		gizmo.press_updated.connect(_on_gizmo_press_updated)
		add_child(gizmo)


func attach(rect :Rect2i, auto_hire := false):
	bound_rect = rect
	if bound_rect.has_area():
		updated.emit(bound_rect)
		if auto_hire:
			hire()
	else:
		dismiss()


func refresh(rect :Rect2i):
	bound_rect = rect
	updated.emit(bound_rect)


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
	
	updated.emit(bound_rect)


func scale_to(gizmo:Gizmo, pos :Vector2i):
	if last_position == pos:
		return
	# use to prevent running while already stop.
	last_position = pos
		
	match gizmo.pivot:
		Pivot.TOP_LEFT: 
			if pos.x < bound_rect.end.x and pos.y < bound_rect.end.y:
				bound_rect.size = bound_rect.end - pos
				bound_rect.position = pos
		Pivot.TOP_CENTER: 
			if pos.y < bound_rect.end.y:
				bound_rect.size.y = bound_rect.end.y - pos.y
				bound_rect.position.y = pos.y
		Pivot.TOP_RIGHT: 
			if pos.x > bound_rect.position.x and pos.y < bound_rect.end.y:
				bound_rect.size.x = pos.x - bound_rect.position.x
				bound_rect.size.y = bound_rect.end.y - pos.y
				bound_rect.position.y = pos.y
		Pivot.MIDDLE_RIGHT:
			if pos.x > bound_rect.position.x:
				bound_rect.size.x = pos.x - bound_rect.position.x
		Pivot.BOTTOM_RIGHT:
			if pos.x > bound_rect.position.x and pos.y > bound_rect.position.y:
				bound_rect.size = pos - bound_rect.position
		Pivot.BOTTOM_CENTER:
			if pos.y > bound_rect.position.y:
				bound_rect.size.y = pos.y - bound_rect.position.y
		Pivot.BOTTOM_LEFT:
			if pos.x < bound_rect.end.x and pos.y > bound_rect.position.y:
				bound_rect.size.y = pos.y - bound_rect.position.y
				bound_rect.size.x = bound_rect.end.x - pos.x
				bound_rect.position.x = pos.x
		Pivot.MIDDLE_LEFT:
			if pos.x < bound_rect.end.x:
				bound_rect.size.x = bound_rect.end.x - pos.x
				bound_rect.position.x = pos.x
	
	for gzm in gizmos:
		set_gizmo_place(gzm)

	updated.emit(bound_rect)


func set_gizmo_place(gizmo):
	var gpos = bound_rect.position
	var gsize = bound_rect.size
	
	match gizmo.pivot:
		Pivot.TOP_LEFT: 
			gizmo.position = Vector2(gpos) + Vector2.ZERO
		Pivot.TOP_CENTER: 
			gizmo.position = Vector2(gpos) + Vector2(gsize.x / 2, 0)
		Pivot.TOP_RIGHT: 
			gizmo.position = Vector2(gpos) + Vector2(gsize.x, 0)
		Pivot.MIDDLE_RIGHT:
			gizmo.position = Vector2(gpos) + Vector2(gsize.x, gsize.y / 2)
		Pivot.BOTTOM_RIGHT:
			gizmo.position = Vector2(gpos) + Vector2(gsize.x, gsize.y)
		Pivot.BOTTOM_CENTER:
			gizmo.position = Vector2(gpos) + Vector2(gsize.x / 2, gsize.y)
		Pivot.BOTTOM_LEFT:
			gizmo.position = Vector2(gpos) + Vector2(0, gsize.y)
		Pivot.MIDDLE_LEFT:
			gizmo.position = Vector2(gpos) + Vector2(0, gsize.y / 2)


func get_pivot_offset(to_size:Vector2i) -> Vector2i:
	var _offset = Vector2i.ZERO
	match pivot:
		Pivot.TOP_LEFT:
			pass
			
		Pivot.TOP_CENTER:
			_offset.x = to_size.x / 2.0

		Pivot.TOP_RIGHT:
			_offset.x = to_size.x

		Pivot.MIDDLE_RIGHT:
			_offset.x = to_size.x
			_offset.y = to_size.y / 2.0

		Pivot.BOTTOM_RIGHT:
			_offset.x = to_size.x
			_offset.y = to_size.y

		Pivot.BOTTOM_CENTER:
			_offset.x = to_size.x / 2.0
			_offset.y = to_size.y

		Pivot.BOTTOM_LEFT:
			_offset.y = to_size.y

		Pivot.MIDDLE_LEFT:
			_offset.y = to_size.y / 2.0
		
		Pivot.CENTER:
			_offset.x = to_size.x / 2.0
			_offset.y = to_size.y / 2.0
			
	return _offset


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



func _on_gizmo_hover_updated(gizmo, status):
	gizmo_hover_updated.emit(gizmo, status)
	

func _on_gizmo_press_updated(gizmo, status):
	gizmo_press_updated.emit(gizmo, status)
	pressed_gizmo = gizmo if status else null


# hook for snapping
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
	
	signal hover_updated(gizmo, status)
	signal press_updated(gizmo, status)


	var pivot := GizmoSizer.Pivot.TOP_LEFT

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
		get = _get_pivot_offset

	var zoom_ratio := 1.0 :
		set(val):
			zoom_ratio = val
			queue_redraw()

	var cursor := Control.CURSOR_ARROW

	var is_hover := false :
		set(val):
			is_hover = val
			hover_updated.emit(self, is_hover)

	var is_pressed := false:
		set(val):
			is_pressed = val
			press_updated.emit(self, is_pressed)


	func _init(_pivot):
		pivot = _pivot
		
		match pivot:
			GizmoSizer.Pivot.TOP_LEFT:
				cursor = Control.CURSOR_FDIAGSIZE
			GizmoSizer.Pivot.TOP_CENTER:
				cursor = Control.CURSOR_VSIZE
			GizmoSizer.Pivot.TOP_RIGHT:
				cursor = Control.CURSOR_BDIAGSIZE
			GizmoSizer.Pivot.MIDDLE_RIGHT:
				cursor = Control.CURSOR_HSIZE
			GizmoSizer.Pivot.BOTTOM_RIGHT:
				cursor = Control.CURSOR_FDIAGSIZE
			GizmoSizer.Pivot.BOTTOM_CENTER:
				cursor = Control.CURSOR_VSIZE
			GizmoSizer.Pivot.BOTTOM_LEFT:
				cursor = Control.CURSOR_BDIAGSIZE
			GizmoSizer.Pivot.MIDDLE_LEFT:
				cursor = Control.CURSOR_HSIZE
			_:
				cursor = Control.CURSOR_POINTING_HAND


	func _get_pivot_offset():
		match pivot:
			GizmoSizer.Pivot.TOP_LEFT:
				return Vector2(size.x, size.y)
			GizmoSizer.Pivot.TOP_CENTER:
				return Vector2(size.x/2, size.y)
			GizmoSizer.Pivot.TOP_RIGHT:
				return Vector2(0, size.y)
			GizmoSizer.Pivot.MIDDLE_RIGHT:
				return Vector2(0, size.y/2)
			GizmoSizer.Pivot.BOTTOM_RIGHT:
				return Vector2(0, 0)
			GizmoSizer.Pivot.BOTTOM_CENTER:
				return Vector2(size.x/2, 0)
			GizmoSizer.Pivot.BOTTOM_LEFT:
				return Vector2(size.x, 0)
			GizmoSizer.Pivot.MIDDLE_LEFT:
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
