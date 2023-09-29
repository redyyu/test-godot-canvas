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
			selection_map_rect = Rect2i(Vector2i.ZERO, size)
#			offset = size / 2  DONT need change offset when `centered` = false

var selection_map := Image.create(size.x, size.y, false, Image.FORMAT_LA8)
var selection_map_rect := Rect2i(Vector2i.ZERO, size)
var zoom_ratio := 1.0:
	set(val):
		zoom_ratio = val
		refresh_material()

var points :PackedVector2Array = []


func _ready():
	centered = false
	refresh_material()


func refresh_material():
	material.set_shader_parameter("frequency", zoom_ratio * 50)
	material.set_shader_parameter("width", 1.0 / zoom_ratio)
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
	
	# doesn't matter the drawn color, material will take care of it.
	match current_type:
		RECTANGLE:
			var rect = get_rect_from_points(points)
			if rect.size == Vector2i.ZERO:
				return
			draw_rect(rect, Color.WHITE, false, 1.0 / zoom_ratio)
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
			draw_arc(center, radius, 0, 360, 36, Color.WHITE, 1 / zoom_ratio)


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
	var ellipse_points = get_ellipse_points_filled(Vector2.ZERO, rect.size)
	
	if selection_map.is_empty() or selection_map.is_invisible():
		_select_multipixels(ellipse_points, rect.position)
		return
		
	match mode:
		Mode.REPLACE:
			selection_map.fill(UNSELECTED_COLOR)
			_select_multipixels(ellipse_points, rect.position)
		Mode.ADD:
			_select_multipixels(ellipse_points, rect.position)
		Mode.SUBTRACT:
			_unselect_multipixels(ellipse_points, rect.position)
		Mode.INTERSECTION:
			for x in selection_map.get_width():
				for y in selection_map.get_height():
					var pos := Vector2i(x, y)
					if not ellipse_points.has(pos + rect.position) \
					   and is_selected(pos):
						_unselect_pixel(pos)


func _select_multipixels(sel_points:PackedVector2Array, _offset:=Vector2i.ZERO):
	for p in sel_points:
		var _p := _offset + Vector2i(p)
		if selection_map_rect.has_point(_p):
			_select_pixel(_p)


func _unselect_multipixels(sel_points:PackedVector2Array, _offset:=Vector2i.ZERO):
	for p in sel_points:
		var _p := _offset + Vector2i(p)
		if selection_map_rect.has_point(_p):
			_unselect_pixel(_p)


func _select_pixel(pos :Vector2i):
	selection_map.set_pixelv(pos, SELECTED_COLOR)


func _unselect_pixel(pos :Vector2i):
	selection_map.set_pixelv(pos, UNSELECTED_COLOR)


func _select_all() -> void:
	selection_map.fill(SELECTED_COLOR)


func _clear_select() -> void:
	selection_map.fill(UNSELECTED_COLOR)



## Algorithm based on http://members.chello.at/easyfilter/bresenham.html
func get_ellipse_points(pos: Vector2i, csize: Vector2i) -> PackedVector2Array:
	var array: PackedVector2Array = []
	var x0 := pos.x
	var x1 := pos.x + (csize.x - 1)
	var y0 := pos.y
	var y1 := pos.y + (csize.y - 1)
	var a := absi(x1 - x0)
	var b := absi(y1 - x0)
	var b1 := b & 1
	var dx := 4 * (1 - a) * b * b
	var dy := 4 * (b1 + 1) * a * a
	var err := dx + dy + b1 * a * a
	var e2 := 0

	if x0 > x1:
		x0 = x1
		x1 += a

	if y0 > y1:
		y0 = y1

	y0 += int(float(b + 1) / 2)  # int and float is for remove warrning.
	y1 = y0 - b1
	a *= 8 * a
	b1 = 8 * b * b

	while x0 <= x1:
		var v1 := Vector2i(x1, y0)
		var v2 := Vector2i(x0, y0)
		var v3 := Vector2i(x0, y1)
		var v4 := Vector2i(x1, y1)
		array.append(v1)
		array.append(v2)
		array.append(v3)
		array.append(v4)

		e2 = 2 * err
		if e2 <= dy:
			y0 += 1
			y1 -= 1
			dy += a
			err += dy

		if e2 >= dx || 2 * err > dy:
			x0 += 1
			x1 -= 1
			dx += b1
			err += dx

	while y0 - y1 < b:
		var v1 := Vector2i(x0 - 1, y0)
		var v2 := Vector2i(x1 + 1, y0)
		var v3 := Vector2i(x0 - 1, y1)
		var v4 := Vector2i(x1 + 1, y1)
		array.append(v1)
		array.append(v2)
		array.append(v3)
		array.append(v4)
		y0 += 1
		y1 -= 1

	return array
	

func get_ellipse_points_filled(pos: Vector2i, 
							   csize: Vector2i,
							   thickness := 1) -> PackedVector2Array:
	var offsetted_size := csize + Vector2i.ONE * (thickness - 1)
	var border := get_ellipse_points(pos, offsetted_size)
	var filling: PackedVector2Array = []

	for x in range(1, ceili(offsetted_size.x / 2.0)):
		var fill := false
		var prev_is_true := false
		for y in range(0, ceili(offsetted_size.y / 2.0)):
			var top_l_p := Vector2i(x, y)
			var bit := border.has(pos + top_l_p)

			if bit and not fill:
				prev_is_true = true
				continue

			if not bit and (fill or prev_is_true):
				filling.append(pos + top_l_p)
				filling.append(pos + Vector2i(x, offsetted_size.y - y - 1))
				filling.append(pos + Vector2i(offsetted_size.x - x - 1, y))
				filling.append(pos + Vector2i(offsetted_size.x - x - 1, 
											  offsetted_size.y - y - 1))

				if prev_is_true:
					fill = true
					prev_is_true = false
			elif bit and fill:
				break

	return border + filling
