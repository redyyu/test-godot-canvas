extends BaseDrawer

class_name PixelDrawer

const NEIGHBOURS: Array[Vector2i] = [
		Vector2i.DOWN,
		Vector2i.RIGHT,
		Vector2i.LEFT,
		Vector2i.UP
	]

const CORNERS: Array[Vector2i] = [
	Vector2i.ONE,
	-Vector2i.ONE,
	Vector2i(-1, 1),
	Vector2i(1, -1)
]

var image := Image.new() :
	set(img):
		image = img
		size = Vector2i(image.get_width(), image.get_height())

var last_pixels := [null, null]
var pixel_perfect := true

var drawn_points := []
var last_position :Vector2i
var fill_inside := false

class PencilOp:
	extends BaseDrawer.ColorOp
	var blending := true
	# blending option is useless here, 
	# because drawing will take draw_pixel many times.
	# (ex., drawing and holding a while)
	# the dst color is take from dst (old) color which is already on canvas.
	# which mean is the color to be blend could be the color just drawing.
	# thats why cause the color look same with src color, 
	# no blender effect at all.
	# blender should working after drawing, such as on layer option.
	
#	func process(src: Color, dst: Color) -> Color:
#		src.a *= strength
#		if blending:
#			return dst.blend(src)
#		else:
#			return src

	func process(src: Color) -> Color:
		src.a *= strength
		return src


func _init() -> void:
	color_op = PencilOp.new()
	

func reset():
	drawn_points = []
	last_pixels = [null, null]


func draw_pixel(position: Vector2i):
	var drawing_color :Color = color_op.process(stroke_color)
	
	var pixel_perfect_color :Color
	if pixel_perfect and stroke_weight_dynamics == 1:
		# pixel_perfect might only work for 1px stroke.
		# only take old color when need it.
		pixel_perfect_color = image.get_pixelv(position)

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
	
	if pixel_perfect_color:
		last_pixels.push_back([position, pixel_perfect_color])
		var corner = last_pixels.pop_front()
		var neighbour = last_pixels[0]

		if corner == null or neighbour == null:
			return
		
		var pos = position  # for short the line only.
		
		if (pos - corner[0]) in CORNERS and (pos - neighbour[0]) in NEIGHBOURS:
			var perfect_coord = Vector2i(neighbour[0].x, neighbour[0].y)
			var perfect_color = neighbour[1]
			if can_draw(perfect_coord):
				image.set_pixelv(perfect_coord, perfect_color)
			last_pixels[0] = corner


func draw_start(pos: Vector2i) -> void:
#	pos = snap_position(pos)
	super.draw_start(pos)
	
	reset()
	
	last_position = pos
	
	if fill_inside:
		drawn_points.append(pos)
	draw_pixel(pos)


func draw_move(pos: Vector2i) -> void:
#	pos = snap_position(pos)
	super.draw_move(pos)
	
	draw_fill_gap(last_position, pos)
	last_position = pos
	if fill_inside:
		drawn_points.append(pos)


func draw_end(pos: Vector2i):
#	pos = snap_position(pos)
	super.draw_end(pos)
	
	if fill_inside:
		drawn_points.append(pos)
		if drawn_points.size() <= 3:
			return
		var v := Vector2i()
		for x in image.get_width():
			v.x = x
			for y in image.get_height():
				v.y = y
				if Geometry2D.is_point_in_polygon(v, drawn_points):
					if draw_spacing_mode:
						v = get_spacing_position(v)
					draw_pixel(v)


# Bresenham's Algorithm, Thanks to 
# https://godotengine.org/qa/35276/tile-based-line-drawing-algorithm-efficiency
func draw_fill_gap(start: Vector2i, end: Vector2i):
	var dx := absi(end.x - start.x)
	var dy := -absi(end.y - start.y)
	var err := dx + dy
	var e2 := err << 1
	var sx := 1 if start.x < end.x else -1
	var sy := 1 if start.y < end.y else -1
	var x := start.x
	var y := start.y
	# This needs to be a dictionary to ensure duplicate coordinates are not being added
	var coords_to_draw := {}
	while !(x == end.x && y == end.y):
		e2 = err << 1
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
		
		var coord := Vector2(x, y)
		
		if draw_spacing_mode:
			coord = get_spacing_position(coord)
			
		coords_to_draw[coord] = 0

	for c in coords_to_draw.keys():
		draw_pixel(c)


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
