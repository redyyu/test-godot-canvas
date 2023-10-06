class_name Selection extends Sprite2D


signal selected(rect)


var size := Vector2i.ONE:
	set(val):
		if val >= Vector2i.ONE:
			size = val
			selection_map.crop(size.x, size.y)
#			offset = size / 2  DONT need Sprite2D offset. `centered = false`

var selection_map := SelectionMap.new(size.x, size.y)
var selected_rect := Rect2i(Vector2i.ZERO, Vector2i.ZERO)

var mask :SelectionMap :
	get: return selection_map

var zoom_ratio := 1.0 :
	set(val):
		zoom_ratio = val
		refresh_material()

var points :PackedVector2Array = []

var is_pressed := false


# DO IT on stage.
#var marching_ants_outline := preload('MarchingAntsOutline.gdshader')
#func _init():
#	var shader_material = ShaderMaterial.new()
#	shader_material.shader = marching_ants_outline
#	material = shader_material


func _ready():
	visible = false
	centered = false
	refresh_material()


func refresh_material():
	material.set_shader_parameter("frequency", zoom_ratio * 50)
	material.set_shader_parameter("width", 1.0 / zoom_ratio)
	queue_redraw()


func update_selection(muted := false):
	if selection_map.is_invisible():
		texture = null
		selected_rect = Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	else:
		texture = ImageTexture.create_from_image(selection_map)
	selected_rect = selection_map.get_used_rect()
	if not muted:
		selected.emit(selected_rect)
	_current_draw = _draw_nothing
	queue_redraw()


func has_selected() -> bool:
	return selected_rect.has_area()


func has_point(point :Vector2i, precisely := false) -> bool:
	if has_selected() and selected_rect.has_point(point):
		if precisely:
			return selection_map.is_selected(point)
		else:
			return true
	else:
		return false


func deselect(muted := false):
	points.clear()
	selection_map.select_none()
	_current_draw = _draw_nothing
	update_selection(muted)


func move_to(to_pos :Vector2i, pivot_offset :=Vector2i.ZERO):
	selection_map.move_to(to_pos, pivot_offset)
	update_selection()


func resize_to(to_size :Vector2i, pivot_offset :=Vector2i.ZERO):
	selection_map.resize_to(to_size, pivot_offset)
	update_selection()


func get_rect_from_points(pts) -> Rect2i:
	return Rect2i(pts[0], pts[pts.size()-1] - pts[0]).abs()


func check_visible(sel_points) -> bool:
	visible = true if sel_points.size() > 1 else false
	return visible

# Rectangle

func selecting_rectangle(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_draw = _draw_rectangle
	points = sel_points
	queue_redraw()


func selected_rectangle(sel_points :Array,
						replace := false,
						subtract := false,
						intersect := false):
	if not check_visible(sel_points):
		return
	var sel_rect := get_rect_from_points(sel_points)
	selection_map.select_rect(sel_rect, replace, subtract, intersect)
	update_selection()
	points.clear()


# Ellipse

func selecting_ellipse(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_draw = _draw_ellipse
	points = sel_points
	queue_redraw()


func selected_ellipse(sel_points :Array,
					  replace := false,
					  subtract := false,
					  intersect := false):
	if not check_visible(sel_points):
		return
	var sel_rect := get_rect_from_points(sel_points)
	selection_map.select_ellipse(sel_rect, replace, subtract, intersect)
	update_selection()
	points.clear()


# Polygon

func selecting_polygon(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_draw = _draw_polyline
	points = sel_points
	queue_redraw()


func selected_polygon(sel_points :Array,
					  replace := false,
					  subtract := false,
					  intersect := false):
	if not check_visible(sel_points):
		return
	selection_map.select_polygon(sel_points, replace, subtract, intersect)
	update_selection()
	points.clear()


# Lasso

func selecting_lasso(sel_points :Array):
	if not check_visible(sel_points):
		return
	_current_draw = _draw_polyline
	points = sel_points
	queue_redraw()


func selected_lasso(sel_points :Array,
					replace := false,
					subtract := false,
					intersect := false):
	if not check_visible(sel_points):
		return
	selection_map.select_polygon(sel_points, replace, subtract, intersect)
	update_selection()
	points.clear()


# Draw selecting lines

func _draw():
	if points.size() > 1:
		_current_draw.call()	
		# switch in `selection_` func.
		# try not use state, so many states in proejcts already.
		# also there is internal useage for this class only.


var _current_draw = _draw_nothing


var _draw_nothing = func():
	pass


var _draw_rectangle = func():
	if points.size() <= 1:
		return
	
	var rect = get_rect_from_points(points)
	if rect.size == Vector2i.ZERO:
		return
	draw_rect(rect, Color.WHITE, false, 1.0 / zoom_ratio)
	# doesn't matter the drawn color, material will take care of it.
	

var _draw_ellipse = func():
	var rect = get_rect_from_points(points)
	if rect.size == Vector2i.ZERO:
		return
	rect = Rect2(rect)
#	draw_rect(rect, Color.WHITE, false, 1.0 / zoom_ratio)
	var radius :float
	var dscale :float
	var center = rect.get_center()
	
	if rect.size.x < rect.size.y:
		radius = rect.size.y / 2.0
		dscale = rect.size.x / rect.size.y
		draw_set_transform(center, 0, Vector2(dscale, 1))
		# the transform is effect whole size 
	else:
		radius = rect.size.x / 2.0
		dscale = rect.size.y / rect.size.x
		draw_set_transform(center, 0, Vector2(1, dscale))
#	draw_rect(Rect2i(Vector2.ZERO, size), Color.WHITE, false, 1.0 / zoom_ratio)
	draw_arc(Vector2.ZERO, radius, 0, 360, 36, Color.WHITE, 1.0 / zoom_ratio)


var _draw_polyline = func():
	draw_polyline(points, Color.WHITE, 1 / zoom_ratio)
	

func _input(event):
	if event is InputEventKey:
		var delta := 1
		
		if Input.is_key_pressed(KEY_SHIFT):
			delta = 10
			
		if Input.is_action_pressed('ui_up'):
			if selected_rect.position.y < delta:
				delta = selected_rect.position.y
			selection_map.move_delta(-delta, VERTICAL)
			update_selection()
		
		elif Input.is_action_pressed('ui_right'):
			var right_remain := size.x - selected_rect.end.x
			if right_remain < delta:
				delta = right_remain
			selection_map.move_delta(delta, HORIZONTAL)
			update_selection()
		
		elif Input.is_action_pressed('ui_down'):
			var bottom_remain := size.y - selected_rect.end.y
			if bottom_remain < delta:
				delta = bottom_remain
			selection_map.move_delta(delta, VERTICAL)
			update_selection()
		
		elif Input.is_action_pressed('ui_left'):
			if selected_rect.position.x < delta:
				delta = selected_rect.position.x
			selection_map.move_delta(-delta, HORIZONTAL)
			update_selection()
	
	
