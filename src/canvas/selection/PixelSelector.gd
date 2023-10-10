class_name PixelSelector extends BaseSelector


func select_start(pos :Vector2i):
	reset()  # no problem reset here, because selection actually is a image.
	if selection.has_point(pos, true):
		if mode == Selection.Mode.REPLACE:
			is_moving = true
		else:
			is_selecting = true
			points.append(pos)
	else:
		if mode == Selection.Mode.REPLACE:
			selection.deselect()
			# when already has a selection,
			# then first click will clear the selection.
		is_selecting = true
		points.append(pos)


# NO NEED move_to and reisze_to, all combined into selection.

#func move_to(to_pos :Vector2i, use_pivot := true):
#	selection.move_to(to_pos, use_pivot)
#

#func resize_to(to_size:Vector2i):
#	selection.resize_to(to_size)
	


