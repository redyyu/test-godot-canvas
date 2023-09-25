extends BaseDrawer

class_name EraseDrawer

var last_position :Vector2i

class EraseOp:
	extends BaseDrawer.ColorOp
	const ERASE_COLOR := Color(1, 1, 1, 0)
	
	func process(dst: Color) -> Color:
		if dst != ERASE_COLOR:
			dst = dst.lerp(ERASE_COLOR, strength)
		return dst


func _init():
	color_op = EraseOp.new()


func draw_pixel(position: Vector2i):
	super.draw_pixel(position)
	
	var color_old := image.get_pixelv(position)
	var drawing_color :Color = color_op.process(color_old)

	# for different stroke weight, draw pixel is one by one, 
	# even the stroke is large weight. actually its draw many pixel once.
	var coords_to_draw := PackedVector2Array()
	var start := position - Vector2i.ONE * (stroke_weight_dynamics >> 1)
	var end := start + Vector2i.ONE * stroke_weight_dynamics
	
	for y in range(start.y, end.y):
		for x in range(start.x, end.x):
			coords_to_draw.append(Vector2(x, y))
	for coord in coords_to_draw:
		if can_draw(coord):
			image.set_pixelv(coord, drawing_color)


func draw_start(pos: Vector2i):
#	pos = snap_position(pos)
	super.draw_start(pos)
	
	last_position = pos
	
	draw_pixel(pos)


func draw_move(pos: Vector2i):
#	pos = snap_position(pos)
	super.draw_move(pos)
	
	draw_fill_gap(last_position, pos)
	last_position = pos


func draw_end(pos: Vector2i):
#	pos = snap_position(pos)
	super.draw_end(pos)


#
#func snap_position(pos: Vector2) -> Vector2:
#	var snapping_distance := Global.snapping_distance / Global.camera.zoom.x
#	if Global.snap_to_rectangular_grid_boundary:
#		var grid_pos := pos.snapped(Global.grid_size)
#		grid_pos += Vector2(Global.grid_offset)
#		# keeping grid_pos as is would have been fine but this adds extra accuracy as to
#		# which snap point (from the list below) is closest to mouse and occupy THAT point
#		var t_l := grid_pos + Vector2(-Global.grid_size.x, -Global.grid_size.y)
#		var t_c := grid_pos + Vector2(0, -Global.grid_size.y)  # t_c is for "top centre" and so on
#		var t_r := grid_pos + Vector2(Global.grid_size.x, -Global.grid_size.y)
#		var m_l := grid_pos + Vector2(-Global.grid_size.x, 0)
#		var m_c := grid_pos
#		var m_r := grid_pos + Vector2(Global.grid_size.x, 0)
#		var b_l := grid_pos + Vector2(-Global.grid_size.x, Global.grid_size.y)
#		var b_c := grid_pos + Vector2(0, Global.grid_size.y)
#		var b_r := grid_pos + Vector2(Global.grid_size)
#		var vec_arr: PackedVector2Array = [t_l, t_c, t_r, m_l, m_c, m_r, b_l, b_c, b_r]
#		for vec in vec_arr:
#			if vec.distance_to(pos) < grid_pos.distance_to(pos):
#				grid_pos = vec
#
#		var grid_point := _get_closest_point_to_grid(pos, snapping_distance, grid_pos)
#		if grid_point != Vector2.INF:
#			pos = grid_point.floor()
#
#	if Global.snap_to_rectangular_grid_center:
#		var grid_center := pos.snapped(Global.grid_size) + Vector2(Global.grid_size / 2)
#		grid_center += Vector2(Global.grid_offset)
#		# keeping grid_center as is would have been fine but this adds extra accuracy as to
#		# which snap point (from the list below) is closest to mouse and occupy THAT point
#		var t_l := grid_center + Vector2(-Global.grid_size.x, -Global.grid_size.y)
#		var t_c := grid_center + Vector2(0, -Global.grid_size.y)  # t_c is for "top centre" and so on
#		var t_r := grid_center + Vector2(Global.grid_size.x, -Global.grid_size.y)
#		var m_l := grid_center + Vector2(-Global.grid_size.x, 0)
#		var m_c := grid_center
#		var m_r := grid_center + Vector2(Global.grid_size.x, 0)
#		var b_l := grid_center + Vector2(-Global.grid_size.x, Global.grid_size.y)
#		var b_c := grid_center + Vector2(0, Global.grid_size.y)
#		var b_r := grid_center + Vector2(Global.grid_size)
#		var vec_arr := [t_l, t_c, t_r, m_l, m_c, m_r, b_l, b_c, b_r]
#		for vec in vec_arr:
#			if vec.distance_to(pos) < grid_center.distance_to(pos):
#				grid_center = vec
#		if grid_center.distance_to(pos) <= snapping_distance:
#			pos = grid_center.floor()
#
#	var snap_to := Vector2.INF
#	if Global.snap_to_guides:
#		for guide in Global.current_project.guides:
#			if guide is SymmetryGuide:
#				continue
#			var s1: Vector2 = guide.points[0]
#			var s2: Vector2 = guide.points[1]
#			var snap := _snap_to_guide(snap_to, pos, snapping_distance, s1, s2)
#			if snap == Vector2.INF:
#				continue
#			snap_to = snap
#
#	if Global.snap_to_perspective_guides:
#		for point in Global.current_project.vanishing_points:
#			if not (point.has("pos_x") and point.has("pos_y")):  # Sanity check
#				continue
#			for i in point.lines.size():
#				if point.lines[i].has("angle") and point.lines[i].has("length"):  # Sanity check
#					var angle := deg_to_rad(point.lines[i].angle)
#					var length: float = point.lines[i].length
#					var start := Vector2(point.pos_x, point.pos_y)
#					var s1 := start
#					var s2 := s1 + Vector2(length * cos(angle), length * sin(angle))
#					var snap := _snap_to_guide(snap_to, pos, snapping_distance, s1, s2)
#					if snap == Vector2.INF:
#						continue
#					snap_to = snap
#	if snap_to != Vector2.INF:
#		pos = snap_to.floor()
#
#	return pos
