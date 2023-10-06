class_name Mover extends Node2D


signal updated(rect, rel_pos, status)
signal applied(rect, rel_pos, status)
signal canceled
signal cursor_changed(cursor)


const MODULATE_COLOR := Color(1, 1, 1, 0.33)

var sizer := GizmoSizer.new()
var pivot :
	get: return sizer.pivot
	set(val): sizer.pivot = val
var relative_position :Vector2i :
	get: return sizer.relative_position

var image := Image.new()
var image_backup := Image.new()  # a backup image for cancel.
var image_mask := Image.new()  # pass selection mask

var move_texture := ImageTexture.new()
var move_image := Image.new() :
	set(val):
		move_image = val
		update_texture()

var canvas_size := Vector2i.ZERO
var line_color := Color.REBECCA_PURPLE:
	set(val):
		line_color = val
		sizer.gizmo_color = line_color

var move_rect := Rect2i(Vector2i.ZERO, Vector2.ZERO):
	set(val):
		move_rect = val
		queue_redraw()

var zoom_ratio := 1.0 :
	set(val):
		zoom_ratio = val
		sizer.zoom_ratio = zoom_ratio
		queue_redraw()

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
	sizer.gizmo_hover_updated.connect(_on_sizer_hover_updated)
	sizer.gizmo_press_updated.connect(_on_sizer_press_updated)
	sizer.drag_updated.connect(_on_sizer_drag_updated)
	sizer.updated.connect(_on_sizer_updated)


func _ready():
	visible = false
	add_child(sizer)


func reset():
	move_rect = Rect2i(Vector2i.ZERO, Vector2.ZERO)
	move_texture = ImageTexture.new()
	move_image = Image.new()
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
	if not has_area():
		image = img  # DO NOT copy_form, image must change runtime.
		image_backup.copy_from(image)
		image_mask.copy_from(mask)
		if image_mask.is_empty() or image_mask.is_invisible():
			move_rect = image.get_used_rect()
		else:
			move_rect = image_mask.get_used_rect()
		sizer.attach(move_rect)
		queue_redraw()

	visible = true


func activate():
	if not has_area() or is_activated:
		# move_rect is setted when launch or transforming.
		return
	is_activated = true
	# for prevent over activate. transform only active once,
	# image will not change and cancelable while in the progress.
	# until applied or canceld.
	
	if image_mask.is_empty() or image_mask.is_invisible():
		# for whole image
		move_image = image.get_region(move_rect)
		image.fill_rect(move_rect, Color.TRANSPARENT)
	else:
		# use tmp image for trigger the setter of transformer_image
		var _tmp = Image.create(move_rect.size.x, 
								move_rect.size.y,
								false, image.get_format())
		_tmp.blit_rect_mask(image, image_mask, move_rect, Vector2i.ZERO)
		move_image = _tmp.duplicate()
					
		_tmp.resize(image.get_width(), image.get_height())
		_tmp.fill(Color.TRANSPARENT)
#			image.fill_rect(move_rect, Color.TRANSPARENT)
		# DO NOT just fill rect, selection might have different shapes.
		image.blit_rect_mask(
			_tmp, image_mask, move_rect, move_rect.position)
	updated.emit(move_rect, relative_position, is_activated)


func cancel():
	is_activated = false
	image.copy_from(image_backup)
	reset()
	canceled.emit()


func apply(use_reset := false):
	is_activated = false
	if has_area():
		move_image.resize(move_rect.size.x, 
							   move_rect.size.y,
							   Image.INTERPOLATE_NEAREST)
		# DO NOT just fill rect, selection might have different shapes.
		image.blit_rect_mask(move_image, move_image,
							 Rect2i(Vector2i.ZERO, move_rect.size),
							 move_rect.position)
		image_backup.copy_from(image)
		# also the image mask must update, because already transformed.
		var _mask = Image.create(image.get_width(), image.get_height(),
								 false, image.get_format())
		_mask.blit_rect(move_image,
						Rect2i(Vector2i.ZERO, move_rect.size),
						move_rect.position)
		image_mask.copy_from(_mask)
		applied.emit(move_rect, relative_position, is_activated)
	if use_reset:
		reset()


func has_area() -> bool:
	return not move_image.is_empty() and move_rect.has_area()


func has_point(point :Vector2i) ->bool:
	return move_rect.has_point(point)


func update_texture():
	if move_image.is_empty():
		move_texture = ImageTexture.new()
	else:
		move_texture.set_image(move_image)


func _input(event):
	if (event is InputEventMouseButton and event.pressed and 
		not is_dragging and not is_scaling):
		var pos = get_local_mouse_position()
		if move_rect.has_point(pos):
			activate()
		else:
			apply(false)


func _draw():
	if visible:
		if has_area():
	#		texture = ImageTexture.create_from_image(image)
			# DO NOT new a texture here, may got blank texture. do it before.
			draw_texture_rect(move_texture, move_rect, false,
							  MODULATE_COLOR if is_dragging else Color.WHITE)
		draw_rect(move_rect, line_color, false, 1.0 / zoom_ratio)


func _on_sizer_hover_updated(gizmo, status):
	cursor_changed.emit(gizmo.cursor if status else null)


func _on_sizer_press_updated(_gizmo, status):
	is_scaling = status


func _on_sizer_updated(rect):
	move_rect = rect
	updated.emit(move_rect, relative_position, is_activated)


func _on_sizer_drag_updated(status):
	is_dragging = status


# external injector

func inject_rect(rect :Rect2i):
	sizer.refresh(rect)
	# pass to sizer only, sizer will take care of many things, suck as pivot.
	# wait sizer finish the job, it will emit a event to Mover.


func inject_sizer_snapping(call_snapping:Callable):
	sizer.get_snapping_weight = call_snapping
	
