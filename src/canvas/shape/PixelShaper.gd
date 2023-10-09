class_name PixelShaper extends BaseShaper


func select_start(pos :Vector2i):
	reset()
	if canvas_rect.has_point(pos):
		is_moving = true
		points.append(pos)
	else:
		# when already has a selection,
		# then first click will clear the selection.
		is_shaping = true
		points.append(pos)


func move_to(to_pos :Vector2i, use_pivot := true):
	shape.move_to(to_pos, use_pivot)


func resize_to(to_size:Vector2i):
	shape.resize_to(to_size)

