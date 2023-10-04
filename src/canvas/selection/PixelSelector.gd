class_name PixelSelector extends BaseSelector

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

var relative_position :Vector2i :  # with pivot, for display on panel
	get:
		var _offset = get_pivot_offset(selected_rect.size)
		return selected_rect.position + _offset


func select_start(pos :Vector2i):
	reset()
	if selection.has_point(pos, true):
		is_moving = true
	else:
		if mode == Mode.REPLACE:
			selection.deselect()
			# when already has a selection,
			# then first click will clear the selection.
		is_selecting = true
		points.append(pos)


func move_to(to_pos :Vector2i, use_pivot := true):
	var pivot_offset := get_pivot_offset(selected_rect.size) \
		if use_pivot else Vector2i.ZERO
		
	var target_pos := to_pos - pivot_offset
	var target_edge := target_pos + selected_rect.size
	if target_pos.x < 0:
		to_pos.x = pivot_offset.x
	if target_pos.y < 0:
		to_pos.y = pivot_offset.y
	if target_edge.x > size.x:
		to_pos.x -= target_edge.x - size.x
	if target_edge.y > size.y:
		to_pos.y -= target_edge.y - size.y

	selection.move_to(to_pos, pivot_offset)


func resize_to(to_size:Vector2i):
	if to_size.x > size.x:
		to_size.x = size.x
	elif to_size.x < 1:
		to_size.x = 1
		
	if to_size.y > size.y:
		to_size.y = size.y
	elif to_size.y < 1:
		to_size.y = 1
	
	selection.resize_to(to_size, get_pivot_offset(to_size))
	

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
