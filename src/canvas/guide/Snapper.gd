extends RefCounted

class_name Snapper

var canvas_size := Vector2.ZERO

var snap_to_rectangular_grid_boundary := false
var snap_to_rectangular_grid_center := false
var snap_to_guides := false
#var snap_to_perspective_guides := false

var snapping_distance := 0.0

var grid_size := Vector2i.ONE
var guides := []


func snap_position(pos: Vector2) -> Vector2:
	if snap_to_rectangular_grid_boundary:
		var grid_pos := pos.snapped(grid_size)
		# keeping grid_pos as is would have been fine 
		# but this adds extra accuracy as to
		# which snap point (from the list below) 
		# is closest to mouse and occupy THAT point
		var t_l := grid_pos + Vector2(-grid_size.x, -grid_size.y)
		# t_c is for "top centre" and so on
		var t_c := grid_pos + Vector2(0, -grid_size.y) 
		var t_r := grid_pos + Vector2(grid_size.x, -grid_size.y)
		var m_l := grid_pos + Vector2(-grid_size.x, 0)
		var m_c := grid_pos
		var m_r := grid_pos + Vector2(grid_size.x, 0)
		var b_l := grid_pos + Vector2(-grid_size.x, grid_size.y)
		var b_c := grid_pos + Vector2(0, grid_size.y)
		var b_r := grid_pos + Vector2(grid_size)
		var vec_arr: PackedVector2Array = [
			t_l, t_c, t_r, m_l, m_c, m_r, b_l, b_c, b_r]
		for vec in vec_arr:
			if vec.distance_to(pos) < grid_pos.distance_to(pos):
				grid_pos = vec

		var grid_point := _get_closest_point_to_grid(pos, 
													 snapping_distance,
													 grid_pos)
		if grid_point != Vector2.INF:
			pos = grid_point.floor()

	if snap_to_rectangular_grid_center:
		var grid_center := pos.snapped(grid_size) + Vector2(grid_size / 2)
		# keeping grid_center as is would have been fine 
		# but this adds extra accuracy as to
		# which snap point (from the list below) 
		# is closest to mouse and occupy THAT point
		var t_l := grid_center + Vector2(-grid_size.x, -grid_size.y)
		# t_c is for "top centre" and so on
		var t_c := grid_center + Vector2(0, -grid_size.y)
		var t_r := grid_center + Vector2(grid_size.x, -grid_size.y)
		var m_l := grid_center + Vector2(-grid_size.x, 0)
		var m_c := grid_center
		var m_r := grid_center + Vector2(grid_size.x, 0)
		var b_l := grid_center + Vector2(-grid_size.x, grid_size.y)
		var b_c := grid_center + Vector2(0, grid_size.y)
		var b_r := grid_center + Vector2(grid_size)
		var vec_arr := [t_l, t_c, t_r, m_l, m_c, m_r, b_l, b_c, b_r]
		for vec in vec_arr:
			if vec.distance_to(pos) < grid_center.distance_to(pos):
				grid_center = vec
		if grid_center.distance_to(pos) <= snapping_distance:
			pos = grid_center.floor()

	var snap_to := Vector2.INF
	if snap_to_guides:
		for guide in guides:
			var s1: Vector2 = guide.points[0]
			var s2: Vector2 = guide.points[1]
			var snap := _snap_to_guide(snap_to, pos, snapping_distance, s1, s2)
			if snap == Vector2.INF:
				continue
			print(snap)
			snap_to = snap

#	if snap_to_perspective_guides:
#		for point in vanishing_points:
#			if not (point.has("pos_x") and point.has("pos_y")):  # Sanity check
#				continue
#			for i in point.lines.size():
#				if point.lines[i].has("angle") and point.lines[i].has("length"):
#					# Sanity check
#					var angle := deg_to_rad(point.lines[i].angle)
#					var length: float = point.lines[i].length
#					var start := Vector2(point.pos_x, point.pos_y)
#					var s1 := start
#					var s2 := s1 + Vector2(length * cos(angle), 
#										   length * sin(angle))
#					var snap := _snap_to_guide(snap_to,
#											   pos, 
#											   snapping_distance,
#											   s1,
#											   s2)
#					if snap == Vector2.INF:
#						continue
#					snap_to = snap
	if snap_to != Vector2.INF:
		pos = snap_to.floor()

	return pos


func _get_closest_point_to_grid(pos: Vector2, 
								distance: float,
								grid_pos: Vector2) -> Vector2:
	# If the cursor is close to the start/origin of a grid cell, snap to that
	var snap_distance := distance * Vector2.ONE
	var closest_point := Vector2.INF
	var rect := Rect2()
	rect.position = pos - (snap_distance / 4.0)
	rect.end = pos + (snap_distance / 4.0)
	if rect.has_point(grid_pos):
		closest_point = grid_pos
		return closest_point
	# If the cursor is far from the grid cell origin but still close to a grid
	# Look for a point close to a horizontal grid line
	var grid_start_hor := Vector2(0, grid_pos.y)
	var grid_end_hor := Vector2(canvas_size.x, grid_pos.y)
	var closest_point_hor := _get_closest_point_to_segment(
		pos, distance, grid_start_hor, grid_end_hor
	)
	# Look for a point close to a vertical grid line
	var grid_start_ver := Vector2(grid_pos.x, 0)
	var grid_end_ver := Vector2(grid_pos.x, canvas_size.y)
	var closest_point_ver := _get_closest_point_to_segment(
		pos, distance, grid_start_ver, grid_end_ver
	)
	# Snap to the closest point to the closest grid line
	var horizontal_distance := (closest_point_hor - pos).length()
	var vertical_distance := (closest_point_ver - pos).length()
	if horizontal_distance < vertical_distance:
		closest_point = closest_point_hor
	elif horizontal_distance > vertical_distance:
		closest_point = closest_point_ver
	elif (horizontal_distance == vertical_distance and 
		  closest_point_hor != Vector2.INF):
		closest_point = grid_pos
	return closest_point


func _get_closest_point_to_segment(pos: Vector2, distance: float,
								   s1: Vector2, s2: Vector2) -> Vector2:
	var test_line := (s2 - s1).rotated(deg_to_rad(90)).normalized()
	var from_a := pos - test_line * distance
	var from_b := pos + test_line * distance
	var closest_point := Vector2.INF
	if Geometry2D.segment_intersects_segment(from_a, from_b, s1, s2):
		closest_point = Geometry2D.get_closest_point_to_segment(pos, s1, s2)
	return closest_point


func _snap_to_guide(snap_to: Vector2, pos: Vector2, distance: float,
					s1: Vector2, s2: Vector2) -> Vector2:
	var closest_point := _get_closest_point_to_segment(pos, distance, s1, s2)
	if closest_point == Vector2.INF:  # Is not close to a guide
		return Vector2.INF
	# Snap to the closest guide
	if snap_to == Vector2.INF or \
	   (snap_to - pos).length() > (closest_point - pos).length():
		snap_to = closest_point

	return snap_to

