class_name SelectionMap extends Image

const SELECTED_COLOR = Color(1, 1, 1, 1)
const UNSELECTED_COLOR = Color(0)

var width :int:
	set(val):
		crop(val, maxi(get_height(), 1))
	get: return get_width()

var height :int:
	set(val):
		crop(maxi(get_width(), 1), val)
	get: return get_height()


func _init():
	var img = Image.create(1,1,false, FORMAT_LA8)
	copy_from(img)


func is_selected(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.y < 0 or pos.x >= width or pos.y >= height:
		return false
	return get_pixelv(pos).a > 0


func select_rect(rect, select := true):
	if select:
		fill_rect(rect, SELECTED_COLOR)
	else:
		fill_rect(rect, UNSELECTED_COLOR)
		

func select_pixel(pos :Vector2i, select := true):
	if select:
		set_pixelv(pos, SELECTED_COLOR)
	else:
		set_pixelv(pos, UNSELECTED_COLOR)


func select_all() -> void:
	fill(SELECTED_COLOR)


func clear() -> void:
	fill(UNSELECTED_COLOR)
