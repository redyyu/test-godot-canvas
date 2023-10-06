class_name PixelSelector extends BaseSelector

signal updated(rect, rel_pos, statsu)
signal canceled

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
var pivot_offset :Vector2i :
	get: return get_pivot_offset(selected_rect.size)
	
var relative_position :Vector2i :  # with pivot, for display on panel
	get: return selected_rect.position + pivot_offset


func set_pivot(pivot_id):
	pivot = pivot_id
	if is_selecting:
		updated.emit(selected_rect, relative_position, is_selecting)


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
	var _offset := pivot_offset if use_pivot else Vector2i.ZERO
		
	var target_pos := to_pos - _offset
	var target_edge := target_pos + selected_rect.size
	if target_pos.x < 0:
		to_pos.x = _offset.x
	if target_pos.y < 0:
		to_pos.y = _offset.y
	if target_edge.x > size.x:
		to_pos.x -= target_edge.x - size.x
	if target_edge.y > size.y:
		to_pos.y -= target_edge.y - size.y

	selection.move_to(to_pos, _offset)


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


func _on_selected(rect : Rect2i):
	if rect.has_area():
		updated.emit(rect, relative_position, true)
	else:
		canceled.emit()
