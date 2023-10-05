class_name FreeTransformer extends Node2D

signal changed(rect)
signal applied(rect)
signal cursor_changed(cursor)


const MODULATE_COLOR := Color(1, 1, 1, 0.33)

var sizer := GizmoSizer.new()

var image := Image.new()
var image_backup := Image.new()  # a backup image for cancel.
var image_mask := Image.new()  # pass selection mask

var transform_texture := ImageTexture.new()
var transform_image := Image.new() :
	set(val):
		transform_image = val
		update_texture()

var canvas_size := Vector2i.ZERO
var line_color := Color.REBECCA_PURPLE:
	set(val):
		line_color = val
		sizer.gizmo_color = line_color

var transform_rect := Rect2i(Vector2i.ZERO, Vector2.ZERO):
	set = update_transform_rect

var zoom_ratio := 1.0 :
	set(val):
		zoom_ratio = val
		sizer.zoom_ratio = zoom_ratio
		queue_redraw()

var is_transforming :bool :
	get: return (not transform_image.is_empty() and
				 transform_rect.has_area())

var is_dragging := false :
	set(val):
		is_dragging = val
		queue_redraw()

var is_scaling := false
var is_activated := false :
	set(val):
		if is_activated != val:
			is_activated = val
			if is_activated:
				sizer.hire()
			else:
				sizer.dismiss()


func _init():
	sizer.gizmo_color = line_color
	sizer.gizmo_hover_changed.connect(_on_sizer_hover_changed)
	sizer.gizmo_press_changed.connect(_on_sizer_press_changed)
	sizer.changed.connect(_on_sizer_changed)
	sizer.drag_started.connect(_on_sizer_drag_started)
	sizer.drag_ended.connect(_on_sizer_drag_ended)


func _ready():
	visible = false
	add_child(sizer)


func reset():
	transform_rect = Rect2i(Vector2i.ZERO, Vector2.ZERO)
	transform_texture = ImageTexture.new()
	transform_image = Image.new()
	image = Image.new()
	image_mask = Image.new()
	image_backup = Image.new()
	is_activated = false
	is_dragging = false
	is_scaling = false
	sizer.dismiss()
	visible = false
	queue_redraw()
	

func lanuch(img :Image, mask :Image):
	if not is_transforming:
		image = img  # DO NOT copy_form, image must change runtime.
		image_backup.copy_from(image)
		image_mask.copy_from(mask)
		if image_mask.is_empty() or image_mask.is_invisible():
			transform_rect = image.get_used_rect()
		else:
			transform_rect = image_mask.get_used_rect()
		sizer.attach(transform_rect)
		changed.emit(transform_rect)
		queue_redraw()

	visible = true


func activate():
	if not transform_rect.has_area() or is_activated:
		# transform_rect is setted when launch or transforming.
		return
	is_activated = true
	# for prevent over activate. transform only active once,
	# image will not change and cancelable while in the progress.
	# until applied or canceld.
	
	if image_mask.is_empty() or image_mask.is_invisible():
		# for whole image
		transform_image = image.get_region(transform_rect)
		image.fill_rect(transform_rect, Color.TRANSPARENT)
	else:
		# use tmp image for trigger the setter of transformer_image
		var _tmp = Image.create(transform_rect.size.x, 
								transform_rect.size.y,
								false, image.get_format())
		_tmp.blit_rect_mask(image, image_mask, transform_rect, Vector2i.ZERO)
		transform_image = _tmp.duplicate()
					
		_tmp.resize(image.get_width(), image.get_height())
		_tmp.fill(Color.TRANSPARENT)
#			image.fill_rect(transform_rect, Color.TRANSPARENT)
		# DO NOT just fill rect, selection might have different shapes.
		image.blit_rect_mask(
			_tmp, image_mask, transform_rect, transform_rect.position)


func cancel():
	is_activated = false
	image.copy_from(image_backup)
	changed.emit(transform_rect)
	reset()


func apply(use_reset := false):
	is_activated = false
	if is_transforming:
		transform_image.resize(transform_rect.size.x, 
							   transform_rect.size.y,
							   Image.INTERPOLATE_NEAREST)
		# DO NOT just fill rect, selection might have different shapes.
		image.blit_rect_mask(transform_image, transform_image,
							 Rect2i(Vector2i.ZERO, transform_rect.size),
							 transform_rect.position)
		image_backup.copy_from(image)
		# also the image mask must update, because already transformed.
		var _mask = Image.create(image.get_width(), image.get_height(),
								 false, image.get_format())
		_mask.blit_rect(transform_image,
						Rect2i(Vector2i.ZERO, transform_rect.size),
						transform_rect.position)
		image_mask.copy_from(_mask)
		changed.emit(transform_rect)
		applied.emit(transform_rect)
	if use_reset:
		reset()


func update_texture():
	if transform_image.is_empty():
		transform_texture = ImageTexture.new()
	else:
		transform_texture.set_image(transform_image)


func update_transform_rect(rect :Rect2i):
	transform_rect = rect
	if is_transforming:
		changed.emit(transform_rect)
		queue_redraw()


func inject_sizer_snapping(call_snapping:Callable):
	sizer.get_snapping = call_snapping


func _input(event):
	if (event is InputEventMouseButton and event.pressed and 
		not is_dragging and not is_scaling):
		var pos = get_local_mouse_position()
		if transform_rect.has_point(pos):
			activate()
		else:
			apply(false)


func _draw():
	if visible and transform_rect:
		if is_transforming:
	#		texture = ImageTexture.create_from_image(image)
			# DO NOT new a texture here, may got blank texture. do it before.
			draw_texture_rect(transform_texture, transform_rect, false,
							  MODULATE_COLOR if is_dragging else Color.WHITE)
		draw_rect(transform_rect, line_color, false, 1.0 / zoom_ratio)


func _on_sizer_hover_changed(gizmo, status):
	cursor_changed.emit(gizmo.cursor if status else null)


func _on_sizer_press_changed(_gizmo, status):
	is_scaling = status


func _on_sizer_changed(rect):
	transform_rect = rect
	

func _on_sizer_drag_started():
	is_dragging = true
	
func _on_sizer_drag_ended():
	is_dragging = false
