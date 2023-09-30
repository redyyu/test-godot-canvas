class_name Selection extends Sprite2D

enum SelType {
	NONE,
	RECTANGLE,
	ELLIPSE,
	POLYGON,
	LASSO,
}

var _current_type := SelType.NONE  # shall not change outside.

var size := Vector2i.ONE:
	set(val):
		if val >= Vector2i.ONE:
			size = val
			selection_map.crop(size.x, size.y)
#			offset = size / 2  DONT need Sprite2D offset. `centered = false`

var selection_map := SelectionMap.new()
var zoom_ratio := 1.0:
	set(val):
		zoom_ratio = val
		refresh_material()

var points :PackedVector2Array = []


func _ready():
	centered = false
	refresh_material()


func refresh_material():
	material.set_shader_parameter("frequency", zoom_ratio * 50)
	material.set_shader_parameter("width", 1.0 / zoom_ratio)
	queue_redraw()


func deselect():
	points.clear()
	selection_map.select_none()
	texture = null
	

func selecting_rect(sel_points :Array):
	_current_type = SelType.RECTANGLE
	points.clear()
	for p in sel_points:
		points.append(p)
	queue_redraw()


func selected_rect(sel_points :Array,
				   replace := false,
				   subtract := false,
				   intersect := false):
	var sel_rect := get_rect_from_points(sel_points)
	selection_map.select_rect(sel_rect, replace, subtract, intersect)
	update_texture()
	points.clear()


func selecting_ellipse(sel_points :Array):
	_current_type = SelType.ELLIPSE
	points.clear()
	for p in sel_points:
		points.append(p)
	queue_redraw()


func selected_ellipse(sel_points :Array,
					  replace := false,
					  subtract := false,
					  intersect := false):
	var sel_rect := get_rect_from_points(sel_points)
	selection_map.select_ellipse(sel_rect, replace, subtract, intersect)
	update_texture()
	points.clear()


func _draw():
	if points.size() <= 1:
		return
	
	# doesn't matter the drawn color, material will take care of it.
	match _current_type:
		SelType.RECTANGLE:
			var rect = get_rect_from_points(points)
			if rect.size == Vector2i.ZERO:
				return
			draw_rect(rect, Color.WHITE, false, 1.0 / zoom_ratio)

		SelType.ELLIPSE:
			var rect = get_rect_from_points(points)
			if rect.size == Vector2i.ZERO:
				return
				
			rect = Rect2(rect)
			var radius :float
			var dscale :float
			var pos := Vector2.ZERO
			var center = rect.get_center()
			if rect.size.x < rect.size.y:
				radius = rect.size.y / 2.0
				dscale = rect.size.x / rect.size.y
				pos.x = (size.x - size.x * dscale) / 2
				draw_set_transform(pos, 0, Vector2(dscale, 1))
				# the transform is effect whole size 
				# (for sprit2D, is texture size)
			else:
				radius = rect.size.x / 2.0
				dscale = rect.size.y / rect.size.x
				pos.y = (size.y - size.y * dscale) / 2
				draw_set_transform(pos, 0, Vector2(1, dscale))
			draw_arc(center, radius, 0, 360, 36, Color.WHITE, 1 / zoom_ratio)


func get_rect_from_points(pts) -> Rect2i:
	return Rect2i(pts[0], pts[pts.size()-1] - pts[0]).abs()


func update_texture():
	texture = ImageTexture.create_from_image(selection_map)
	queue_redraw()

