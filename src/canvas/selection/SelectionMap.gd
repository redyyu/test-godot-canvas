class_name SelectionMap extends Image

const SELECTED_COLOR = Color(1, 1, 1, 1)
const UNSELECTED_COLOR = Color(0)

var width :int:
	set(val):
		crop(maxi(val, 1), get_height())
	get: return get_width()

var height :int:
	set(val):
		crop(get_width(), maxi(val, 1))
	get: return get_height()

var map_rect :Rect2i :
	get : return Rect2i(Vector2i.ZERO, Vector2i(get_width(), get_height()))


func _init(w:int, h:int):
	var img = Image.create(maxi(w, 1), maxi(h, 1), false, FORMAT_LA8)
	copy_from(img)
	# make sure image with Alpha


func is_selected(pos: Vector2i) -> bool:
#	if pos.x < 0 or pox.y < 0 or pox.x >= get_width() or pos.y >= get_height():
	if not map_rect.has_point(pos):
		return false
	return get_pixelv(pos).a > 0


func select_rect(rect :Rect2i,
				 replace:=false, subtract:=false, intersect:=false):
	if rect.size < Vector2i.ONE:
		return
	if is_invisible():
		fill_rect(rect, SELECTED_COLOR)
		return
	
	if replace:
		fill(UNSELECTED_COLOR)
	
	if intersect:
		for x in width:
			for y in height:
				var pos := Vector2i(x, y)
				if is_selected(pos) and not rect.has_point(pos):
					# DO NOT use 2 Rect check each other.
					# because the source selected shape can not be sure.
					select_pixel(pos, true)
	else:
		if subtract:
			fill_rect(rect, UNSELECTED_COLOR)
		else:
			fill_rect(rect, SELECTED_COLOR)


func select_ellipse(rect :Rect2i, 
					replace:=false, subtract:=false, intersect:=false):
	if rect.size < Vector2i.ONE:
		return
	var ellipse = get_ellipse_points_filled(rect.size)
	
	if is_invisible():
		fill_ellipse(ellipse, SELECTED_COLOR, rect.position)
		return
	
	if replace:
		fill(UNSELECTED_COLOR)
		
	if intersect:
		var tmp_map := Image.create(width, height, false, Image.FORMAT_LA8)
		for p in ellipse:
			p += Vector2(rect.position)
			if map_rect.has_point(p):
				tmp_map.set_pixelv(p, SELECTED_COLOR)
		blit_rect_mask(tmp_map, self, map_rect, Vector2i.ZERO)
#		for x in width:
#			for y in height:
#				var pos := Vector2i(x, y)
#				if is_selected(pos) and not tmp_map.get_pixelv(pos).a > 0:
#					select_pixel(pos, true)
	else:
		if subtract:
			fill_ellipse(ellipse, UNSELECTED_COLOR, rect.position)
		else:
			fill_ellipse(ellipse, SELECTED_COLOR, rect.position)


func select_polygon(polygon:PackedVector2Array, 
					replace:=false, subtract:=false, intersect:=false):
	if is_invisible():
		fill_polygon(polygon, SELECTED_COLOR)
		return
	
	if replace:
		fill(UNSELECTED_COLOR)
	
	if intersect:
		for x in width:
			for y in height:
				var pos := Vector2i(x, y)
				if is_selected(pos) and \
				   not Geometry2D.is_point_in_polygon(pos, polygon):
					select_pixel(pos, true)
	else:
		if subtract:
			fill_polygon(polygon, UNSELECTED_COLOR)
		else:
			fill_polygon(polygon, SELECTED_COLOR)


func select_magic(points:PackedVector2Array, 
				  replace:=false, subtract:=false, intersect:=false):
	if is_invisible():
		fill_points(points, SELECTED_COLOR)
		return
	
	if replace:
		fill(UNSELECTED_COLOR)
	
	if intersect:
		for x in width:
			for y in height:
				var pos := Vector2i(x, y)
				if is_selected(pos) and points.has(pos):
					select_pixel(pos, true)
	else:
		if subtract:
			fill_points(points, UNSELECTED_COLOR)
		else:
			fill_points(points, SELECTED_COLOR)


#func select_multipixels(sel_points :PackedVector2Array,
#						sel_offset := Vector2i.ZERO,
#						subtract := false):
#	for p in sel_points:
#		var _p := sel_offset + Vector2i(p)
#		if map_rect.has_point(_p):
#			select_pixel(_p, subtract)


func select_pixel(pos :Vector2i, subtract:=false):
	if subtract:
		set_pixelv(pos, UNSELECTED_COLOR)
	else:
		set_pixelv(pos, SELECTED_COLOR)


func select_all():
	fill(SELECTED_COLOR)


func select_none():
	fill(UNSELECTED_COLOR)


func fill_ellipse(ellipse :PackedVector2Array, color:Color,
				  pos_offset := Vector2.ZERO):
	for pos in ellipse:
		if pos_offset:
			pos += pos_offset
		if map_rect.has_point(pos):
			set_pixelv(pos, color)


func fill_polygon(polygon:PackedVector2Array,
				  color:Color, 
				  pos_offset := Vector2i.ZERO):
	for x in width:
		for y in height:
			var pos :Vector2i
			if pos_offset:
				pos = Vector2i(x, y) + pos_offset
			else:
				pos = Vector2i(x, y)

			if map_rect.has_point(pos) and \
			   Geometry2D.is_point_in_polygon(pos, polygon):
				set_pixelv(pos, color)


func fill_points(points:PackedVector2Array, color:Color):
	
	for pos in points:
		if map_rect.has_point(pos):
			set_pixelv(pos, color)

# DONT NEED THIS, already replace to navtive way.
#func get_selected_rect() ->Rect2i:
#	var rect = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
#	var start := Vector2i(-1, -1)
#	var end := Vector2i(-1, -1)
#	# DO NOT use `if start:` because the first possible point will be .ZERO.
#
#	if is_invisible():
#		return rect
#
#	for x in width:
#		for y in height:
#			var pos := Vector2i(x, y)
#			if get_pixelv(pos).a > 0:
#				if start >= Vector2i.ZERO:
#					if start.x > pos.x:
#						start.x = pos.x
#					if start.y > pos.y:
#						start.y = pos.y
#				else:
#					start = pos
#
#				if end >= Vector2i.ZERO:
#					if end.x < pos.x:
#						end.x = pos.x
#					if end.y < pos.y:
#						end.y = pos.y
#				else:
#					end = pos
#
#	if (end - start) > Vector2i.ZERO:
#		rect = Rect2i(start, end - start + Vector2i.ONE) 
#		# size must + Vector2i.ONE, it is for make sure last point count.
#		# ex. for size (10, 10), the start (0, 0), end (9, 9).
#		# but end - start will be (9, 9).
#	return rect 


func move_delta(delta :int, orientation:Orientation):
	if is_invisible():
		return
	var sel_rect := get_used_rect()
	var tmp_img := get_region(sel_rect)
	var dest_pos := sel_rect.position
	match orientation:
		HORIZONTAL: dest_pos.x += delta
		VERTICAL: dest_pos.y += delta
	var tmp_img_size := Vector2i(tmp_img.get_width(), tmp_img.get_height())
	
	fill(UNSELECTED_COLOR)
	blit_rect(tmp_img, Rect2i(Vector2i.ZERO, tmp_img_size), dest_pos)

#	DONT NEED THIS, already replace to navtive way.
#	var tmp_img := Image.new()
#	tmp_img.copy_from(self)
#	select_none()
#	for x in tmp_img.get_width():
#		for y in tmp_img.get_height():
#			var pos := Vector2i(x, y)
#			var to_pos :Vector2i
#			match orientation:
#				HORIZONTAL: to_pos = Vector2i(x + delta, y)
#				VERTICAL: to_pos = Vector2i(x, y + delta)
#			if tmp_img.get_pixelv(pos).a > 0 and map_rect.has_point(to_pos):
#				select_pixel(to_pos)


func move_to(to_position :Vector2i, pivot_offset := Vector2i.ZERO):
	# pivot_offset is for when to_position is by different pivot.
	# when move the selection with keyboard or mouse drag, 
	# the pivot_offset should be ignore by leave it to ZERO.
	if is_invisible():
		return 
	var tmp_img := get_region(get_used_rect())
	var dest_pos :Vector2i = to_position - pivot_offset
	var tmp_img_size := Vector2i(tmp_img.get_width(), tmp_img.get_height())
	
	fill(UNSELECTED_COLOR)
	blit_rect(tmp_img, Rect2i(Vector2i.ZERO, tmp_img_size), dest_pos)
	
#	DONT NEED THIS, already replace to navtive way.
#	var sel_rect := get_used_rect()
#	var tmp_img := Image.new()
#	tmp_img.copy_from(self)
#	select_none()
#	var move_pos :Vector2i = (to_position - pivot_offset) - sel_rect.position
#
#	for x in tmp_img.get_width():
#		for y in tmp_img.get_height():
#			var pos := Vector2i(x, y)
#			var to_pos := pos + move_pos
#			if tmp_img.get_pixelv(pos).a > 0 and map_rect.has_point(to_pos):
#				select_pixel(to_pos)
				

func resize_to(to_size :Vector2i, pivot_offset :=Vector2i.ZERO):
	if is_invisible():
		return 
	var sel_rect := get_used_rect()
	var tmp_img := get_region(get_used_rect())
	var coef := Vector2(pivot_offset) / Vector2(to_size)
	var size_diff :Vector2i = Vector2(sel_rect.size - to_size) * coef
	var dest_pos :Vector2i = sel_rect.position + size_diff
	
	tmp_img.resize(to_size.x, to_size.y, INTERPOLATE_NEAREST)
	
	fill(UNSELECTED_COLOR)
	blit_rect(tmp_img, Rect2i(Vector2i.ZERO, to_size), dest_pos)

#	DONT NEED THIS, already replace to navtive way.
#	var tmp_img := Image.create(sel_rect.size.x, sel_rect.size.y, 
#								false, FORMAT_LA8)
#
#	var x_range = range(sel_rect.position.x, sel_rect.end.x)
#	var y_range = range(sel_rect.position.y, sel_rect.end.y)
#
#	for x in x_range:
#		for y in y_range:
#			var pos := Vector2i(x, y)
#			if is_selected(pos):
#				var tmp_pos = pos - sel_rect.position
#				tmp_img.set_pixelv(tmp_pos, SELECTED_COLOR)
#
#	tmp_img.resize(to_size.x, to_size.y, INTERPOLATE_NEAREST)
#	select_none()
#	var coef := Vector2(pivot_offset) / Vector2(to_size)
#	var size_diff :Vector2i = Vector2(sel_rect.size - to_size) * coef
#	var move_pos :Vector2i = sel_rect.position + size_diff
#
#	for x in tmp_img.get_width():
#		for y in tmp_img.get_height():
#			var pos := Vector2i(x, y)
#			var new_pos := pos + move_pos
#			if tmp_img.get_pixelv(pos).a > 0 and map_rect.has_point(new_pos):
#				select_pixel(new_pos)


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
