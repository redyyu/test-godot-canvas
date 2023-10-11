class_name Guide extends Line2D

signal released(guide)
signal pressed(guide)
signal hovered(guide)
signal leaved(guide)
signal locked(guide)

const DEFAULT_WIDTH := 2
const LINE_COLOR := Color.REBECCA_PURPLE
const SNAPPING_DISTANCE := 12.0

var relative_position := Vector2i.ZERO
# one of coordinate x or y is useless,
# because guide is cross over the artboard.
# y used for HORIZONTAL, x used for VERTICAL.

#var relative_offset := Vector2.ZERO
# it is calculated position to parent scene when zoom is 1.0
# use to keep the right position when place guide while is zoomed.
# DO NOT do this, it's not precisely.

var orientation := HORIZONTAL
var is_pressed := false
var is_hovered := false
var is_locked := false :
	set (val):
		is_locked = val
		is_pressed = false
		is_hovered = false
		locked.emit(self)


func _ready():
#	default_color = LINE_COLOR.lerp(Color(.2, .2, .65), .6)
	default_color = LINE_COLOR
	modulate.a = 0.6
	width = DEFAULT_WIDTH


func _input(event: InputEvent):
	if is_locked:
		return
		
	# grab a guide
	if (event is InputEventMouseButton and event.pressed and 
		event.button_index == MOUSE_BUTTON_LEFT):
		if orientation == HORIZONTAL and is_hovered:
			if not is_pressed:
				is_pressed = true
				pressed.emit(self)
		elif orientation == VERTICAL and is_hovered:
			if not is_pressed:
				is_pressed = true
				pressed.emit(self)
	
	# release a guide
	elif (event is InputEventMouseButton and not event.pressed):
		if is_pressed:
			is_pressed = false
			released.emit(self)
	
	# drag a guide		
	elif event is InputEventMouseMotion and is_pressed:
		match orientation:
			HORIZONTAL:
				position.y = get_artboard_mouse_position.call().y
			VERTICAL: 
				position.x = get_artboard_mouse_position.call().x
	
	# mouse over 
	elif event is InputEventMouseMotion:
		if orientation == HORIZONTAL:
			if abs(position.y - get_artboard_mouse_position.call().y) < 3:
				# check mouse is closet to guide.
				if not is_hovered:
					is_hovered = true
					hovered.emit(self)
			else:
				if is_hovered:
					is_hovered = false
					leaved.emit(self)
			
		elif orientation == VERTICAL:
			if abs(position.x - get_artboard_mouse_position.call().x) < 3:
				# check mouse is closet to guide.
				if not is_hovered:
					is_hovered = true
					hovered.emit(self)
			else:
				if is_hovered:
					is_hovered = false
					leaved.emit(self)


func set_guide(orient :Orientation, size :Vector2):
	is_pressed = true
	clear_points()
	orientation = orient
	match orientation:
		HORIZONTAL:
			add_point(Vector2(0, 0))
			add_point(Vector2(size.x, 0))
		VERTICAL:
			add_point(Vector2(0, 0))
			add_point(Vector2(0, size.y))


func resize(size :Vector2):
	match orientation:
		HORIZONTAL:
			points[1].x = size.x
		VERTICAL:
			points[1].y = size.y


func snap_to(pos :Vector2i):
	match orientation:
		HORIZONTAL:
			if abs(relative_position.y - pos.y) < SNAPPING_DISTANCE:
				relative_position.y = pos.y
		VERTICAL:
			if abs(relative_position.x - pos.x) < SNAPPING_DISTANCE:
				relative_position.x = pos.x


var get_artboard_mouse_position = func():
	return get_parent().get_local_mouse_position()
