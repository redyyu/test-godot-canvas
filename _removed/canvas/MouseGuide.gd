extends Line2D

enum Types { VERTICAL, HORIZONTAL }
const INPUT_WIDTH := 4
@export var type := 0
var track_mouse := true

var guide_color :Color = Color.WHITE
var camera_zoom :Vector2 = Vector2.ZERO
var camera_offset :Vector2 = Vector2.ZERO
var viewport_size: Vector2 = Vector2.ZERO
var show_mouse_guides :bool = false
var can_draw :bool = false
var has_focus :bool = false
var mouse_pos :Vector2 = Vector2.ZERO
var project_size :Vector2i = Vector2i.ZERO


func _ready() -> void:
	# Add a subtle difference to the normal guide color by mixing in some green
	default_color = guide_color.lerp(Color(0.2, 0.92, 0.2), .6)
	width = camera_zoom.x * 2
	draw_guide_line()


func draw_guide_line():
	if type == Types.HORIZONTAL:
		points[0] = Vector2(-19999, 0)
		points[1] = Vector2(19999, 0)
	else:
		points[0] = Vector2(0, 19999)
		points[1] = Vector2(0, -19999)


func _input(event: InputEvent) -> void:
	if not show_mouse_guides or not can_draw or not has_focus:
		visible = false
		return
	visible = true
	if event is InputEventMouseMotion:
		var tmp_transform = get_canvas_transform().affine_inverse()
		var mouse_point = (tmp_transform.basis_xform(mouse_pos) +
						   tmp_transform.origin).snapped(Vector2(0.5, 0.5))

		if Rect2(Vector2.ZERO, project_size).has_point(mouse_point):
			visible = true
		else:
			visible = false
			return
		if type == Types.HORIZONTAL:
			points[0].y = mouse_point.y
			points[1].y = mouse_point.y
		else:
			points[0].x = mouse_point.x
			points[1].x = mouse_point.x
	queue_redraw()


func _draw() -> void:
	width = camera_zoom.x * 2

	# viewport_poly is an array of the points that make up the corners of the viewport
	var viewport_poly = [Vector2.ZERO, 
						 Vector2(viewport_size.x, 0),
						 viewport_size, Vector2(0,
						 viewport_size.y)]
	# Adjusting viewport_poly to take into account the camera offset, zoom, and rotation
	for p in range(viewport_poly.size()):
		viewport_poly[p] = (viewport_poly[p] * camera_zoom + Vector2(
			(camera_offset.x - (viewport_size.x / 2) * camera_zoom.x),
			(camera_offset.y - (viewport_size.y / 2) * camera_zoom.y)
		))

	draw_set_transform(viewport_poly[0], 0.0, camera_zoom * 2)
