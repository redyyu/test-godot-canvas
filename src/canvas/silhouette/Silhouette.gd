class_name Silhouette extends Node2D

signal updated(rect, rel_pos, status)
signal applied(rect)
signal canceled
signal refresh_canvas

enum {
	NONE,
	RECTANGLE,
	ELLIPSE,
	POLYGON,
	LINE,
}

var type := NONE :
	set = set_type

var image := Image.new()
var pivot := Pivot.TOP_LEFT  # Pivot class in /core.
var pivot_offset :Vector2i :
	get: return get_pivot_offset(shaped_rect.size)

var relative_position :Vector2i :  # with pivot, for display on panel
	get: return shaped_rect.position + pivot_offset

var size := Vector2i.ZERO
var boundary : Rect2i :
	get: return Rect2i(Vector2i.ZERO, size)

var touch_rect := Rect2i(Vector2i.ZERO, Vector2i.ZERO)
var shaped_rect := Rect2i(Vector2i.ZERO, Vector2i.ZERO)

var shape_color := Color.BLACK

#var shaped_angle = null # angle 0 ~360.
var start_point := Vector2i.ZERO
var end_point := Vector2i.ZERO

var zoom_ratio := 1.0
var last_position :Variant = null # prevent same with mouse pos from beginning.

var opt_as_square := false :
	get: return opt_as_square and force_as_square
	
var opt_from_center := false :
	get: return opt_from_center and force_from_center
	
var opt_fill := false :
	get: return opt_fill and not force_outline

var force_as_square := false
var force_from_center := false
var force_outline := false

var stroke_width := 2
var division := 5
var edge_expands := 0

var is_pressed := false


func set_type(val):
	if type != val:
		type = val
		force_as_square = false
		force_from_center = false
		force_outline = false
		if type == POLYGON:
			force_as_square = true
		if type == LINE:
			force_outline = true
		

func attach(img :Image):
	image = img
	size = Vector2i(image.get_width(), image.get_height())


func apply():
	match type:
		RECTANGLE: shaped_rectangle()
		ELLIPSE: shaped_ellipse()
		LINE: shaped_line()
		POLYGON: shaped_polygon()
	reset()
	applied.emit(shaped_rect)


func cancel():
	reset()
	canceled.emit()


func reset():
#	shaped_angle = null
	_current_shape = null
	shaped_rect = Rect2i()
	touch_rect = Rect2i()
	update_shape()


func set_pivot(pivot_id):
	pivot = pivot_id
	if has_area():
		updated.emit(shaped_rect, relative_position, true)


func update_shape():
	if has_area():
		updated.emit(shaped_rect, relative_position, true)
		visible = true
	else:
		updated.emit(shaped_rect, relative_position, false)
		visible = false
	queue_redraw()


func check_visible(sel_points) -> bool:
	visible = true if sel_points.size() > 1 else false
	# less 2 points is needed,
	# because require 2 points to make 1 pixel.
	return visible
	

func has_area():
#	return shaped_rect.has_area()
	return touch_rect.has_area()


func has_point(pos :Vector2i):
#	return shaped_rect.has_point(pos)
	return touch_rect.has_point(pos)


func get_drag_offset(pos :Vector2i):
	return pos - shaped_rect.position


# Rectangle

func shaping_rectangle(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_shape = _shape_rectangle
	start_point = sel_points[0]
	end_point = sel_points[sel_points.size() - 1]
	sel_points = parse_two_points(sel_points)
	shaped_rect = points_to_rect(sel_points)
	touch_rect = shaped_rect.grow(stroke_width)
	update_shape()


func shaped_rectangle():
	if not has_area():
		return
	if opt_fill:
		image.fill_rect(shaped_rect, shape_color)
	else:
		var tmp_img = Image.create(image.get_width(),
								   image.get_height(),
								   false,
								   image.get_format())
		var rect = shaped_rect.grow(-stroke_width)
		tmp_img.fill_rect(shaped_rect, shape_color)
		tmp_img.fill_rect(rect, Color.TRANSPARENT)
		image.blend_rect(tmp_img, shaped_rect, shaped_rect.position)
	refresh_canvas.emit()
	update_shape()


var _shape_rectangle = func():
	if opt_fill:
		draw_rect(shaped_rect, shape_color, true)
	else:
		var _rect = shaped_rect.grow(round(-stroke_width / 2.0))
		# stroke is middle of the rect boundary.
		draw_rect(_rect, shape_color, false, stroke_width / zoom_ratio)


# Ellipse

func shaping_ellipse(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_shape = _shape_ellipse
	start_point = sel_points[0]
	end_point = sel_points[sel_points.size() - 1]
	sel_points = parse_two_points(sel_points)
	shaped_rect = points_to_rect(sel_points)
	touch_rect = shaped_rect.grow(stroke_width)
	update_shape()


func shaped_ellipse():
	if not has_area():
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
		var inner_rect := shaped_rect.grow(-stroke_width)
		var inner_ellipse = get_ellipse_points_filled(inner_rect.size)
		for pos in ellipse:
			if inner_ellipse.has(pos - Vector2(stroke_width, stroke_width)):
				continue
			if pos_offset:
				pos += pos_offset
			if boundary.has_point(pos):
				image.set_pixelv(pos, shape_color)

	refresh_canvas.emit()
	update_shape()


var _shape_ellipse = func():
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
		radius -= stroke_width / 2.0  # fix draw_arc stroke expand.
		draw_arc(Vector2.ZERO, radius, 0, 360, 36, 
				 shape_color, stroke_width / zoom_ratio)
		# draw_arc place center to ZERO, use tranform move to the right center.


# Line

func shaping_line(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_shape = _shape_line
	start_point = sel_points[0]
	end_point = sel_points[sel_points.size() - 1]
	var angle = get_angle_360(start_point, end_point)
	sel_points = parse_two_points(sel_points)
	shaped_rect = points_to_rect(sel_points)
	var dpoints := get_diagonal_from_rect(shaped_rect, angle)
	start_point = dpoints[0]
	end_point = dpoints[1]
	touch_rect = shaped_rect.grow(stroke_width)
	update_shape()


func shaped_line():
	if not has_area():
		return
	var distance := Vector2(start_point).distance_to(end_point)
	var line := get_lines_form_points(start_point, end_point, distance)
	for i in line.size():
		var pos = line[i]
		var rect := Rect2i(pos - Vector2.ONE * (stroke_width >> 1), 
						   Vector2.ONE * stroke_width)
		if boundary.has_point(pos):
			image.fill_rect(rect, shape_color)

	refresh_canvas.emit()
	update_shape()


var _shape_line = func():
	# DO NOT draw_line might not exactly same when applied.
	var distance := Vector2(start_point).distance_to(end_point)
	var line := get_lines_form_points(start_point, end_point, distance)
	for pos in line:
		if boundary.has_point(pos):
			var rect := Rect2i(pos - Vector2.ONE * (stroke_width >> 1), 
							   Vector2.ONE * stroke_width)
			draw_rect(rect, shape_color)


# Polygon

func shaping_polygon(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_shape = _shape_polygon
	start_point = sel_points[0]
	end_point = sel_points[sel_points.size() - 1]
	sel_points = parse_two_points(sel_points)
	shaped_rect = points_to_rect(sel_points)
	touch_rect = shaped_rect.grow(stroke_width)
	update_shape()
	
	# DO NOT NEED those
#	var diff = shaped_rect.size.x - shaped_rect.size.y
#	if diff > 0:
#		touch_rect = shaped_rect.grow_individual(-diff/2.0, 0, -diff/2.0, 0)
#	else:
#		touch_rect = shaped_rect.grow_individual(0, diff/2.0, 0, diff/2.0)
#		# diff is negative


func shaped_polygon():
	if not has_area():
		return
	var radius = minf(shaped_rect.size.x / 2.0, shaped_rect.size.y / 2.0)
	var center = shaped_rect.get_center()
	if opt_fill:
		var polygon = get_arc_division_polygon(
			radius, division, center, start_point.y > end_point.y)
		polygon = parse_polygon_expends(polygon, shaped_rect.get_center())
		for x in range(shaped_rect.position.x, shaped_rect.end.x):
			for y in range(shaped_rect.position.y, shaped_rect.end.y):
				var pos = Vector2i(x, y)
				if boundary.has_point(pos) and \
				   Geometry2D.is_point_in_polygon(pos, polygon):
					image.set_pixelv(pos, shape_color)
	else:
		var outer_polygon = get_arc_division_polygon(
			radius, division, center,
			start_point.y > end_point.y)
		outer_polygon = parse_polygon_expends(outer_polygon,
											  shaped_rect.get_center())
		var inner_polygon = get_arc_division_polygon(
			radius - stroke_width, division, center,
			start_point.y > end_point.y)
		inner_polygon = parse_polygon_expends(inner_polygon,
											  shaped_rect.get_center())
		for x in range(touch_rect.position.x, touch_rect.end.x -1):
			for y in range(touch_rect.position.y, touch_rect.end.y -1):
				var pos = Vector2(x, y)
				if boundary.has_point(pos) and \
				   Geometry2D.is_point_in_polygon(pos, outer_polygon) and \
				   not Geometry2D.is_point_in_polygon(pos, inner_polygon):
					image.set_pixelv(pos, shape_color)
	refresh_canvas.emit()
	update_shape()

var _shape_polygon = func():
	var radius = minf(shaped_rect.size.x / 2.0, shaped_rect.size.y / 2.0)
	var center = shaped_rect.get_center()
	var polygon = get_arc_division_polygon(radius,
										   division,
										   center,
										   start_point.y > end_point.y)
	polygon = parse_polygon_expends(polygon, shaped_rect.get_center())
#	draw_rect(touch_rect, Color.BLUE, false, 1)
#	draw_rect(shaped_rect, Color.RED, false, 1)
	# calculte polygon by rect. for shape who need some point not on the rect.
	# use the ratio of width and height to adjustment. such as Pentagram.
	if opt_fill:
		draw_colored_polygon(polygon, shape_color)
	else:
#		draw_polyline(polygon, shape_color, stroke_width / zoom_ratio)
		# DO NOT draw_polyline might not exactly same when applied.
		var outer_polygon = get_arc_division_polygon(
			radius, division, center,
			start_point.y > end_point.y)
		outer_polygon = parse_polygon_expends(outer_polygon,
											  shaped_rect.get_center())
		var inner_polygon = get_arc_division_polygon(
			radius - stroke_width, division, center,
			start_point.y > end_point.y)
		inner_polygon = parse_polygon_expends(inner_polygon,
											  shaped_rect.get_center())
		for x in range(touch_rect.position.x, touch_rect.end.x -1):
			for y in range(touch_rect.position.y, touch_rect.end.y -1):
				var pos = Vector2(x, y)
				if boundary.has_point(pos) and \
				   Geometry2D.is_point_in_polygon(pos, outer_polygon) and \
				   not Geometry2D.is_point_in_polygon(pos, inner_polygon):
					draw_rect(Rect2i(pos, Vector2i.ONE), shape_color)
					# draw one pixel rect, same with set_pixelv on image.


# Draw shaping

func _draw():
	if has_area() and _current_shape is Callable:
		_current_shape.call()
	# switch in `selection_` func.
	# try not use state, so many states in proejcts already.
	# also there is internal useage for this class only.

var _current_shape = null


func _input(event):
	if event is InputEventKey:

		if Input.is_key_pressed(KEY_ENTER) and \
		   event.is_command_or_control_pressed():
			apply()
			# send signal to Shaper,
			# it's for separaate different shaper current using.
			# because shaper does not have _input, but sillhouette has.
		elif Input.is_key_pressed(KEY_ESCAPE):
			cancel()
		
		var delta := 1
		if Input.is_key_pressed(KEY_SHIFT):
			delta = 10

		if Input.is_action_pressed('ui_up'):
			if shaped_rect.position.y < delta:
				delta = shaped_rect.position.y
			move_delta(-delta, VERTICAL)

		elif Input.is_action_pressed('ui_right'):
			var right_remain := boundary.size.x - shaped_rect.end.x
			if right_remain < delta:
				delta = right_remain
			move_delta(delta, HORIZONTAL)

		elif Input.is_action_pressed('ui_down'):
			var bottom_remain := boundary.size.y - shaped_rect.end.y
			if bottom_remain < delta:
				delta = bottom_remain
			move_delta(delta, VERTICAL)

		elif Input.is_action_pressed('ui_left'):
			if shaped_rect.position.x < delta:
				delta = shaped_rect.position.x
			move_delta(-delta, HORIZONTAL)


func move_delta(delta :int, orientation:Orientation):
	if not has_area():
		return

	match orientation:
		HORIZONTAL: shaped_rect.position.x += delta
		VERTICAL: shaped_rect.position.y += delta
	touch_rect = shaped_rect.grow(stroke_width)
	update_shape()


func move_to(to_pos :Vector2i, use_pivot := true):
	var _offset := pivot_offset if use_pivot else Vector2i.ZERO
	
	var target_pos := to_pos - _offset
	var target_edge := target_pos + shaped_rect.size
	if target_pos.x < 0:
		to_pos.x = _offset.x
	if target_pos.y < 0:
		to_pos.y = _offset.y
	if target_edge.x > size.x:
		to_pos.x -= target_edge.x - size.x
	if target_edge.y > size.y:
		to_pos.y -= target_edge.y - size.y
		
	shaped_rect.position = to_pos - _offset
	touch_rect = shaped_rect.grow(stroke_width)
#	var touch_diff = Vector2i(touch_rect.size.x / 2, touch_rect.size.y / 2)
#	touch_rect.position = shaped_rect.get_center() - touch_diff
	update_shape()


func drag_to(pos, drag_offset):
	if last_position == pos:
		return
	# use to prevent running while already stop.
	last_position = pos
	pos -= drag_offset  # DO calculate drag_offset just pressed.
	
	# convert to local pos from the rect zero pos. 
	# DO NOT use get_local_mouse_position, because bound_rect is not zero pos.
	shaped_rect.position  = snapping(shaped_rect, pos)
	touch_rect = shaped_rect.grow(stroke_width)
#	var touch_diff = Vector2i(touch_rect.size.x / 2, touch_rect.size.y / 2)
#	touch_rect.position = shaped_rect.get_center() - touch_diff
	update_shape()


func resize_to(to_size :Vector2i):
	to_size = to_size.clamp(Vector2i.ONE, size)
	var coef := Vector2(get_pivot_offset(to_size)) / Vector2(to_size)
	var size_diff :Vector2i = Vector2(shaped_rect.size - to_size) * coef
	shaped_rect.position += size_diff
	shaped_rect.size = to_size
	touch_rect = shaped_rect.grow(stroke_width)
	update_shape()


# snapping
func snapping(rect: Rect2i, pos :Vector2i) -> Vector2i:
	return _snapping.call(rect, pos)

# hook for snapping
var _snapping = func(_rect: Rect2i, pos :Vector2i) -> Vector2i:
	# pass original postion if no hook.
	return pos


func inject_snapping(callable :Callable):
	_snapping = callable


# calculate points and shape

func parse_polygon_expends(polygon:PackedVector2Array,
						   center_point:Vector2) -> PackedVector2Array:
	for i in polygon.size():
		if i % 2 :
			polygon[i] -= (polygon[i] - center_point) * edge_expands / 100
	return polygon
	

func get_lines_form_points(start :Vector2i, end :Vector2i,
						   points_total:float=0.0) -> PackedVector2Array:
	var x_spacing := (end.x - start.x) / float(points_total + 1)
	var y_spacing := (end.y - start.y) / float(points_total + 1)
	
	var line :PackedVector2Array = []
	for i in range(1, points_total + 1):
		line.append(Vector2i(
			floor(start.x + i * x_spacing),
			floor(start.y + i * y_spacing),
		))
	return line


func get_diagonal_from_rect(rect:Rect2i, angle:int) -> PackedVector2Array:
	var start :Vector2i = rect.position
	var end :Vector2i = rect.end
	if angle >= 0 and angle < 90:
		pass
	elif angle >= 90 and angle < 180:
		start = Vector2i(rect.end.x, rect.position.y)
		end = Vector2i(rect.position.x, rect.end.y)
	elif angle >= -180 and angle < -90:
		start = rect.end
		end = rect.position
	elif angle > -90 and angle < 0:
		start = Vector2i(rect.position.x, rect.end.y)
		end = Vector2i(rect.end.x, rect.position.y)
	return [start, end]


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


func make_square(rect:Rect2i) ->Rect2i:
	# Make rect 1:1 while centering it on the mouse
	var sel_size = Vector2i.ONE * maxi(rect.size.x, rect.size.y)
	if rect.position.x < rect.end.x:
		rect.end.x = rect.position.x + sel_size.x
	else:
		rect.end.x = rect.position.x - sel_size.x
	
	if rect.position.y < rect.end.y:
		rect.end.y = rect.position.y + sel_size.y
	else:
		rect.end.y = rect.position.y - sel_size.y
	return rect


func parse_two_points(sel_points:PackedVector2Array):
	if sel_points.size() < 2:
		# skip parse if points is not up to 2.
		# the _draw() will take off the rest.
		return sel_points
		
	var pts :PackedVector2Array = []
	var start := sel_points[0]
	var end := sel_points[sel_points.size() - 1]
	var sel_size :Vector2i = (start - end).abs()
	
	if opt_as_square:
		# Make rect 1:1 while centering it on the mouse
		sel_size = Vector2i.ONE * maxi(sel_size.x, sel_size.y)
		if start.x < end.x:
			end.x = start.x + sel_size.x
		else:
			end.x = start.x - sel_size.x
		
		if start.y < end.y:
			end.y = start.y + sel_size.y
		else:
			end.y = start.y - sel_size.y

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


func get_angle_360(p1:Vector2, p2:Vector2) -> int:
	return round(p1.angle_to_point(p2) * 180.0 / PI)


func get_arc_division_polygon(radius:int,
							  div_count:int,
							  center:Vector2,
							  reverse:= false) ->PackedVector2Array:
	var polygon :PackedVector2Array = []
	var radians :float = (PI / 180.0) * round(360.0 / div_count)
	for i in div_count:
		if reverse:
			polygon.append(Vector2(
				center.x + radius * sin(radians * i),
				center.y + radius * cos(radians * i)
			).floor())
		else:
			polygon.append(Vector2(
				center.x - radius * sin(radians * i),
				center.y - radius * cos(radians * i)
			).floor())
	polygon.append(polygon[0])  # join first point
	return polygon


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
