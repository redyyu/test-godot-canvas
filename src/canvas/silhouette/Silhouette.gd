class_name Silhouette extends Node2D

signal updated(rect, rel_pos)
signal canceled
signal refresh_canvas

var image := Image.new()
var pivot := Pivot.TOP_LEFT  # Pivot class in /core.
var pivot_offset :Vector2i :
	get: return get_pivot_offset(shaped_rect.size)

var relative_position :Vector2i :  # with pivot, for display on panel
	get: return shaped_rect.position + pivot_offset

var size := Vector2i.ZERO
var boundary : Rect2i :
	get: return Rect2i(Vector2i.ZERO, size)
var shaped_rect := Rect2i(Vector2i.ZERO, Vector2i.ZERO)
var shape_color := Color.BLACK

var zoom_ratio := 1.0

var points :PackedVector2Array = []

var opt_as_square := false
var opt_from_center := false
var opt_fill := false

var stroke_weight := 2

var is_pressed := false


func attach(img :Image):
	image = img
	size = Vector2i(image.get_width(), image.get_height())


func reset():
	_current_shape = null
	points.clear()


func set_pivot(pivot_id):
	pivot = pivot_id
	if shaped_rect.has_area():
		updated.emit(shaped_rect, relative_position)


func update_shape():
	if points.size() < 1:
		shaped_rect = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
		canceled.emit(shaped_rect, relative_position)
		visible = false
	else:
		shaped_rect = points_to_rect(points)
		updated.emit(shaped_rect, relative_position)
		visible = true
	queue_redraw()


func points_to_rect(pts) -> Rect2i:
	if pts.size() < 1:
		return Rect2i()
	var start = null
	var end = null
	for p in pts:
		if start == null:
			start = p
		if end == null:
			end = p
			
		if start.x > p.x:
			start.x = p.x
		if start.y > p.y:
			start.y = p.y
		
		if end.x < p.x:
			end.x = p.x
		if end.y < p.y:
			end.y = p.y
	return Rect2i(start, end - start).abs()


func check_visible(sel_points) -> bool:
	visible = true if sel_points.size() > 1 else false
	# less 2 points is needed,
	# because require 2 points to make 1 pixel.
	return visible
	

func has_area():
	return shaped_rect.has_area()


func has_point(pos :Vector2i):
	return shaped_rect.has_point(pos)


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


func parse_two_points(sel_points:PackedVector2Array):
	if sel_points.size() < 2:
		# skip parse if points is not up to 2.
		# the _draw() will take off the rest.
		return sel_points
		
	var pts :PackedVector2Array = []
	var start := sel_points[0]
	var end := sel_points[sel_points.size() - 1]
	var sel_size := (start - end).abs()
	
	if opt_as_square:
		# Make rect 1:1 while centering it on the mouse
		var square_size :float = max(sel_size.x, sel_size.y)
		sel_size = Vector2(square_size, square_size)
		end = start - sel_size if start > end else start + sel_size

	if opt_from_center:
		var _start = Vector2(start.x, start.y)
		if start.x < end.x:
			start.x -= sel_size.x
			end.x += 2 * sel_size.x
		else:
			_start.x = end.x - 2 * sel_size.x
			end.x = start.x + sel_size.x
			start.x = _start.x
			
		if start.y < end.y:
			start.y -= sel_size.y
			end.y += 2 * sel_size.y
		else:
			_start.y = end.y - 2 * sel_size.y
			end.y = start.y + sel_size.y
			start.y = _start.y
			
	pts.append(start)
	pts.append(end)
	return pts


# Rectangle

func shaping_rectangle(sel_points :Array):
	sel_points = parse_two_points(sel_points)
	if not check_visible(sel_points):
		return
	_current_shape = _shape_rectangle
	points = sel_points
	update_shape()


func shaped_rectangle():
	if not shaped_rect.has_area():
		return
	if opt_fill:
		image.fill_rect(shaped_rect, shape_color)
	else:
		var tmp_img = Image.create(image.get_width(), image.get_height(), false, image.get_format())
		var rect = shaped_rect.grow(-stroke_weight)
		tmp_img.fill_rect(shaped_rect, shape_color)
		tmp_img.fill_rect(rect, Color.TRANSPARENT)
		image.blend_rect(tmp_img, shaped_rect, shaped_rect.position)
	refresh_canvas.emit()
	points.clear()
	update_shape()


# Ellipse

func shaping_ellipse(sel_points :Array):
	sel_points = parse_two_points(sel_points)
	if not check_visible(sel_points):
		return
	_current_shape = _shape_ellipse
	points = sel_points
	update_shape()


func shaped_ellipse():
	if not shaped_rect.has_area():
		return
	var pos_offset :Vector2 = shaped_rect.position
	if opt_fill:
		var ellipse = get_ellipse_points_filled(shaped_rect.size)
		for pos in ellipse:
			if pos_offset:
				pos += pos_offset
			if boundary.has_point(pos):
				image.set_pixelv(pos, shape_color)
	else:
		var ellipse = get_ellipse_points_filled(shaped_rect.size)
		var inner_rect := shaped_rect.grow(-stroke_weight)
		var inner_ellipse = get_ellipse_points_filled(inner_rect.size)
		for pos in ellipse:
			if inner_ellipse.has(pos - Vector2(stroke_weight, stroke_weight)):
				continue
			if pos_offset:
				pos += pos_offset
			if boundary.has_point(pos):
				image.set_pixelv(pos, shape_color)

	refresh_canvas.emit()
	points.clear()
	update_shape()


# Polygon

func shaping_polygon(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_shape = _shape_polyline
	points = sel_points
	queue_redraw()


func shaped_polygon(sel_points :Array):
	if not check_visible(sel_points):
		return
#	shaped_map.shape_polygon(sel_points, shape_color)
	points.clear()
	update_shape()


# Draw selecting lines

func _draw():
	if points.size() > 1:
		if _current_shape is Callable:
			_current_shape.call()
		# switch in `selection_` func.
		# try not use state, so many states in proejcts already.
		# also there is internal useage for this class only.

var _current_shape = null


var _shape_rectangle = func():
	if points.size() <= 1:
		return
	if not shaped_rect.has_area():
		return
	if opt_fill:
		draw_rect(shaped_rect, shape_color, true)
	else:
		var _rect = shaped_rect.grow(round(-stroke_weight / 2.0))
		# stroke is middle of the rect boundary.
		draw_rect(_rect, shape_color, false, stroke_weight / zoom_ratio)


var _shape_ellipse = func():
	if not shaped_rect.has_area():
		return
	var radius :float
	var dscale :float
	var center = shaped_rect.get_center()
	
	var _rect = Rect2(shaped_rect)
	if _rect.size.x < _rect.size.y:
		radius = _rect.size.y / 2.0
		dscale = _rect.size.x / _rect.size.y
		draw_set_transform(center, 0, Vector2(dscale, 1))
		# the transform is effect whole size 
	else:
		radius = _rect.size.x / 2.0
		dscale = _rect.size.y / _rect.size.x
		draw_set_transform(center, 0, Vector2(1, dscale))

	if opt_fill:
		draw_circle(Vector2.ZERO, radius, shape_color)
	else:
		radius -= stroke_weight / 2.0  # fix draw_arc stroke expand.
		draw_arc(Vector2.ZERO, radius, 0, 360, 36, 
				 shape_color, stroke_weight / zoom_ratio)
		# draw_arc place center to ZERO, use tranform move to the right center.


var _shape_polyline = func():
	draw_polyline(points, shape_color, 1 / zoom_ratio)
	
#
#func _input(event):
#	if event is InputEventKey:
#		var delta := 1
#
#		if Input.is_key_pressed(KEY_ESCAPE):
#			reset()
#
#		if Input.is_key_pressed(KEY_SHIFT):
#			delta = 10
#
#		if Input.is_action_pressed('ui_up'):
#			if shaped_rect.position.y < delta:
#				delta = shaped_rect.position.y
#			move_delta(-delta, VERTICAL)
#
#		elif Input.is_action_pressed('ui_right'):
#			var right_remain := boundary.size.x - shaped_rect.end.x
#			if right_remain < delta:
#				delta = right_remain
#			move_delta(delta, HORIZONTAL)
#
#		elif Input.is_action_pressed('ui_down'):
#			var bottom_remain := boundary.size.y - shaped_rect.end.y
#			if bottom_remain < delta:
#				delta = bottom_remain
#			move_delta(delta, VERTICAL)
#
#		elif Input.is_action_pressed('ui_left'):
#			if shaped_rect.position.x < delta:
#				delta = shaped_rect.position.x
#			move_delta(-delta, HORIZONTAL)


#func move_delta(delta :int, orientation:Orientation):
#	if has_area():
#		return
#	match orientation:
#		HORIZONTAL: shaped_rect.position.x += delta
#		VERTICAL: shaped_rect.position.y += delta
#	update_shape()


#func move_to(to_pos :Vector2i, use_pivot := true):
#	var _offset := pivot_offset if use_pivot else Vector2i.ZERO
#
#	var target_pos := to_pos - _offset
#	var target_edge := target_pos + shaped_rect.size
#	if target_pos.x < 0:
#		to_pos.x = _offset.x
#	if target_pos.y < 0:
#		to_pos.y = _offset.y
#	if target_edge.x > size.x:
#		to_pos.x -= target_edge.x - size.x
#	if target_edge.y > size.y:
#		to_pos.y -= target_edge.y - size.y
#	shaped_rect.position = to_pos
#	queue_redraw()
#
#
#func resize_to(to_size :Vector2i):
#	if has_area():
#		return 
#	var coef := Vector2(pivot_offset) / Vector2(to_size)
#	var size_diff :Vector2i = Vector2(shaped_rect.size - to_size) * coef
#	shaped_rect.position += size_diff
#	shaped_rect.size = to_size
#	update_shape()


## Algorithm based on http://members.chello.at/easyfilter/bresenham.html
func get_ellipse_points_filled(csize: Vector2i) -> PackedVector2Array:
	var border := get_ellipse_border_points(csize)
	var filling: PackedVector2Array = []

	for x in range(1, ceili(csize.x / 2.0)):
		var _fill := false
		var prev_is_true := false
		for y in range(0, ceili(csize.y / 2.0)):
			var top_l_p := Vector2i(x, y)
			var bit := border.has(top_l_p)

			if bit and not _fill:
				prev_is_true = true
				continue

			if not bit and (_fill or prev_is_true):
				filling.append(top_l_p)
				filling.append(Vector2i(x, csize.y - y - 1))
				filling.append(Vector2i(csize.x - x - 1, y))
				filling.append(Vector2i(csize.x - x - 1, 
										csize.y - y - 1))

				if prev_is_true:
					_fill = true
					prev_is_true = false
			elif bit and _fill:
				break

	return border + filling


func get_ellipse_border_points(csize: Vector2i) -> PackedVector2Array:
	var border: PackedVector2Array = []
	var x0 := 0
	var x1 := csize.x - 1
	var y0 := 0
	var y1 := csize.y - 1
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

	y0 += int((b + 1) / 2.0)
	# DO NOT round() here, might cause unexcepted border here.
	# int and float is for remove warrning.
	
	y1 = y0 - b1
	a *= 8 * a
	b1 = 8 * b * b

	while x0 <= x1:
		var v1 := Vector2i(x1, y0)
		var v2 := Vector2i(x0, y0)
		var v3 := Vector2i(x0, y1)
		var v4 := Vector2i(x1, y1)
		border.append(v1)
		border.append(v2)
		border.append(v3)
		border.append(v4)

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
		border.append(v1)
		border.append(v2)
		border.append(v3)
		border.append(v4)
		y0 += 1
		y1 -= 1

	return border
