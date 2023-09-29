class_name Selection extends Sprite2D

const SELECTED_COLOR = Color(1, 1, 1, 1)
const UNSELECTED_COLOR = Color(0)

enum SelectType {
	NONE,
	RECTANGLE,
	CIRCLE,
	POLYGON,
	LASSO,
}
var type := SelectType.NONE

enum Mode {
	REPLACE,
	ADD,
	SUBTRACT,
	INTERSECTION,
}

var mode := Mode.REPLACE

var size := Vector2i.ONE:
	set(val):
		if val >= Vector2i.ONE:
			size = val
			selection_map.crop(size.x, size.y)
			offset = size / 2
		
var selection_map := Image.create(size.x, size.y, false, Image.FORMAT_LA8)
var zoom_ratio := 1.0:
	set(val):
		zoom_ratio = val
		refresh_material()

var points :PackedVector2Array = []


func _ready():
	refresh_material()


func refresh_material():
	material.set_shader_parameter("frequency", zoom_ratio * 50)
	material.set_shader_parameter("width", 1.0 / zoom_ratio)
	queue_redraw()


func deselect():
	points.clear()
	clear_select()
	texture = null
	

func selecting(sel_points :Array, sel_type:SelectType):
	type = sel_type
	points.clear()
	for p in sel_points:
		points.append(p)
	queue_redraw()
	

func selected_rect(sel_points :Array):
	match mode:
		Mode.REPLACE:
			clear_select()
			select_rect(get_rect_from_points(sel_points))
		Mode.ADD:
			select_rect(get_rect_from_points(sel_points))
		Mode.SUBTRACT:
			select_rect(get_rect_from_points(sel_points), false)
		Mode.INTERSECTION:
			pass
	
	update_texture()
	points.clear()


func _draw():
	match type:
		SelectType.RECTANGLE:
			if points.size() > 1:
				var rect = get_rect_from_points(points)
				draw_rect(rect, Color.WHITE, false, 1.0 / zoom_ratio)
				# doesn't matter the color, material will take care of is.


func get_rect_from_points(pts):
	return Rect2i(pts[0], pts[pts.size()-1] - pts[0])


func update_texture():
	texture = ImageTexture.create_from_image(selection_map)
	queue_redraw()


# for selection map
func is_selected(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.y < 0 or pos.x >= size.x or pos.y >= size.y:
		return false
	return selection_map.get_pixelv(pos).a > 0


func select_rect(rect, select := true):
	if select:
		selection_map.fill_rect(rect, SELECTED_COLOR)
	else:
		selection_map.fill_rect(rect, UNSELECTED_COLOR)


func select_pixel(pos :Vector2i, select := true):
	if select:
		selection_map.set_pixelv(pos, SELECTED_COLOR)
	else:
		selection_map.set_pixelv(pos, UNSELECTED_COLOR)


func select_all() -> void:
	selection_map.fill(SELECTED_COLOR)


func clear_select() -> void:
	selection_map.fill(UNSELECTED_COLOR)
