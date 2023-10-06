class_name MoveSizer extends GizmoSizer


const MODULATE_COLOR := Color(1, 1, 1, 0.33)

var image := Image.new()
var image_backup := Image.new()  # a backup image for cancel.
var image_mask := Image.new()  # pass selection mask

var backup_rect := Rect2i()

var preview_texture := ImageTexture.new()
var preview_image := Image.new() :
	set(val):
		preview_image = val
		update_texture()


func reset():
	super.reset()
	preview_texture = ImageTexture.new()
	preview_image = Image.new()
	image = Image.new()
	image_mask = Image.new()
	image_backup = Image.new()
	

func lanuch(img :Image, mask :Image):
	frozen(false)
	if not has_area():
		image = img  # DO NOT copy_form, image must change runtime.
		image_backup.copy_from(image)
		image_mask.copy_from(mask)
		if image_mask.is_empty() or image_mask.is_invisible():
			backup_rect = image.get_used_rect()
			attach(backup_rect)
		else:
			backup_rect = image_mask.get_used_rect()
			attach(backup_rect)


func hire():
	if is_activated:
		return
	# image will not change and cancelable while in the progress.
	# until applied or canceld.
	if not has_image():
		if image_mask.is_empty() or image_mask.is_invisible():
			# for whole image
			preview_image = image.get_region(bound_rect)
			image.fill_rect(bound_rect, Color.TRANSPARENT)
		else:
			# use tmp image for trigger the setter of transformer_image
			var _tmp = Image.create(bound_rect.size.x, 
									bound_rect.size.y,
									false, image.get_format())
			_tmp.blit_rect_mask(image, image_mask, bound_rect, Vector2i.ZERO)
			preview_image = _tmp.duplicate()
						
			_tmp.resize(image.get_width(), image.get_height())
			_tmp.fill(Color.TRANSPARENT)
	#			image.fill_rect(move_rect, Color.TRANSPARENT)
			# DO NOT just fill rect, selection might have different shapes.
			image.blit_rect_mask(_tmp, image_mask, 
								 bound_rect, bound_rect.position)
	
	super.hire()


func cancel(use_reset := false, muted := false):
	image.copy_from(image_backup)
	bound_rect = backup_rect
	preview_image = Image.new()
	super.cancel(use_reset, muted)


func apply(use_reset := false, muted := false):
	if has_area() and has_image():
		preview_image.resize(bound_rect.size.x, 
							 bound_rect.size.y,
							 Image.INTERPOLATE_NEAREST)
		# DO NOT just fill rect, selection might have different shapes.
		image.blit_rect_mask(preview_image, preview_image,
							 Rect2i(Vector2i.ZERO, bound_rect.size),
							 bound_rect.position)
		image_backup.copy_from(image)
		backup_rect = bound_rect
		# also the image mask must update, because already transformed.
		var _mask = Image.create(image.get_width(), image.get_height(),
								 false, image.get_format())
		_mask.blit_rect(preview_image,
						Rect2i(Vector2i.ZERO, bound_rect.size),
						bound_rect.position)
		image_mask.copy_from(_mask)
		preview_image = Image.new()

		super.apply(use_reset, muted)


func has_image() -> bool:
	return not preview_image.is_empty()


func update_texture():
	if preview_image.is_empty():
		preview_texture = ImageTexture.new()
	else:
		preview_texture.set_image(preview_image)


func _draw():
	if has_area(): # careful has_area might be ovrride.
		var draw_color = line_color
		if not is_activated:
			draw_color.a = 0.5
		draw_rect(bound_rect, draw_color, false, line_width / zoom_ratio)
	
		if has_image():
	#		texture = ImageTexture.create_from_image(image)
			# DO NOT new a texture here, may got blank texture. do it before.
			draw_texture_rect(preview_texture, bound_rect, false,
							  MODULATE_COLOR if is_dragging else Color.WHITE)
	
