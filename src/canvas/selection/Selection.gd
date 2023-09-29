class_name Selection extends Sprite2D

const SELECTED_COLOR = Color(1, 1, 1, 1)
const UNSELECTED_COLOR = Color(0)

enum {
	NONE,
	RECTANGLE,
	CIRCLE,
	POLYGON,
	LASSO,
}
var current_type := NONE

enum Mode {  # setting in Selector
	REPLACE,
	ADD,
	SUBTRACT,
	INTERSECTION,
}

var size := Vector2i.ONE:
	set(val):
		if val >= Vector2i.ONE:
			size = val
			selection_map.crop(size.x, size.y)
#			offset = size / 2  DONT need change offset when `centered` = false

var selection_map := Image.create(size.x, size.y, false, Image.FORMAT_LA8)
var zoom_ratio := 1.0:
	set(val):
		zoom_ratio = val
		refresh_material()

var points :PackedVector2Array = []


func _ready():
	centered = false
	refresh_material()


func refresh_material():
#	material.set_shader_parameter("frequency", zoom_ratio * 50)
#	material.set_shader_parameter("width", 1.0 / zoom_ratio)
	queue_redraw()


func deselect():
	points.clear()
	_clear_select()
	texture = null
	

func selecting(sel_points :Array, sel_type):
	current_type = sel_type
	points.clear()
	for p in sel_points:
		points.append(p)
	queue_redraw()
	

func selected(sel_points :Array, mode:Mode, sel_type):
	match sel_type:
		RECTANGLE:
			_select_rect(get_rect_from_points(sel_points), mode)
		CIRCLE:
			_select_circle(get_rect_from_points(sel_points), mode)
	update_texture()
	points.clear()


func _draw():
	if points.size() <= 1:
		return

	match current_type:
		RECTANGLE:
			var rect = get_rect_from_points(points)
			draw_rect(rect, Color.WHITE, false, 1.0 / zoom_ratio)
			# doesn't matter the color, material will take care of is.
		CIRCLE:
			var rect = get_rect_from_points(points)
			if rect.size == Vector2i.ZERO:
				return
				
			rect = Rect2(rect)
			var radius :float
			var dscale :float
			var pos := Vector2.ZERO
			var center = rect.get_center()
			if rect.size.x < rect.size.y:
				radius = rect.size.y / 2.0
				dscale = rect.size.x / rect.size.y
				pos.x = (size.x - size.x * dscale) / 2
				draw_set_transform(pos, 0, Vector2(dscale, 1))
				# the transform is effect whole size 
				# (for sprit2D, is texture size)
			else:
				radius = rect.size.x / 2.0
				dscale = rect.size.y / rect.size.x
				pos.y = (size.y - size.y * dscale) / 2
				draw_set_transform(pos, 0, Vector2(1, dscale))
#			draw_rect(Rect2i(Vector2i.ZERO, size), Color.WHITE, false, 1.0 / zoom_ratio)
			draw_arc(center, radius, 0, 360, 36, Color.WHITE, 1 / zoom_ratio)
#			draw_circle(rect.position, radius, Color.WHITE)
			# doesn't matter the color, material will take care of is.


func get_rect_from_points(pts):
	return Rect2i(pts[0], pts[pts.size()-1] - pts[0]).abs()


func update_texture():
	texture = ImageTexture.create_from_image(selection_map)
	queue_redraw()


# for selection map
func is_selected(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.y < 0 or pos.x >= size.x or pos.y >= size.y:
		return false
	return selection_map.get_pixelv(pos).a > 0


func _select_rect(rect, mode):
	if selection_map.is_empty() or selection_map.is_invisible():
		selection_map.fill_rect(rect, SELECTED_COLOR)
		return
		
	match mode:
		Mode.REPLACE:
			selection_map.fill(UNSELECTED_COLOR)
			selection_map.fill_rect(rect, SELECTED_COLOR)
		Mode.ADD:
			selection_map.fill_rect(rect, SELECTED_COLOR)
		Mode.SUBTRACT:
			selection_map.fill_rect(rect, UNSELECTED_COLOR)
		Mode.INTERSECTION:
			for x in selection_map.get_width():
				for y in selection_map.get_height():
					var pos := Vector2i(x, y)
					if not rect.has_point(pos) and is_selected(pos):
						_unselect_pixel(pos)


func _select_circle(rect, mode):
	if selection_map.is_empty() or selection_map.is_invisible():
		selection_map.fill_rect(rect, SELECTED_COLOR)
		return
		
	match mode:
		Mode.REPLACE:
			selection_map.fill(UNSELECTED_COLOR)
			selection_map.fill_rect(rect, SELECTED_COLOR)
		Mode.ADD:
			selection_map.fill_rect(rect, SELECTED_COLOR)
		Mode.SUBTRACT:
			selection_map.fill_rect(rect, UNSELECTED_COLOR)
		Mode.INTERSECTION:
			for x in selection_map.get_width():
				for y in selection_map.get_height():
					var pos := Vector2i(x, y)
					if not rect.has_point(pos) and is_selected(pos):
						_unselect_pixel(pos)


func _select_pixel(pos :Vector2i):
	selection_map.set_pixelv(pos, SELECTED_COLOR)


func _unselect_pixel(pos :Vector2i):
	selection_map.set_pixelv(pos, UNSELECTED_COLOR)


func _select_all() -> void:
	selection_map.fill(SELECTED_COLOR)


func _clear_select() -> void:
	selection_map.fill(UNSELECTED_COLOR)
