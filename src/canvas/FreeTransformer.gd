class_name FreeTransformer extends Node2D

signal changed(rect)

const MODULATE_COLOR := Color(1, 1, 1, 0.66)

var image := Image.new()

var transform_texture := ImageTexture.new()
var transform_image := Image.new() :
	set(val):
		transform_image = val
		update_texture()

var canvas_size := Vector2i.ZERO
var line_color := Color.REBECCA_PURPLE

var transform_rect := Rect2i(Vector2i.ZERO, Vector2.ZERO):
	set = update_transform_rect

var zoom_ratio := 1.0 :
	set(val):
		zoom_ratio = val
		queue_redraw()

var is_transforming :bool :
	get: return (not transform_image.is_empty() and
				 transform_rect.has_area())


func _ready():
	visible = false


func reset():
	transform_rect =  Rect2i(Vector2i.ZERO, Vector2.ZERO)
	transform_texture = ImageTexture.new()
	transform_image = Image.new()
	image = Image.new()
	visible = false
	queue_redraw()
	

func lanuch(img :Image, mask :Image):
	if not is_transforming:
		image = img
		if mask.is_empty() or mask.is_invisible():
			transform_rect = image.get_used_rect()
			if transform_rect.has_area():
				transform_image = image.get_region(transform_rect)
				image.fill_rect(transform_rect, Color.TRANSPARENT)
		else:
			transform_rect = mask.get_used_rect()
			# use tmp image for trigger the setter of transformer_image
			var _tmp = Image.create(transform_rect.size.x, 
									transform_rect.size.y,
									false, image.get_format())
			_tmp.blit_rect_mask(image, mask, transform_rect, Vector2i.ZERO)
			transform_image = _tmp.duplicate()
						
			_tmp.resize(image.get_width(), image.get_height())
			_tmp.fill(Color.TRANSPARENT)
#			image.fill_rect(transform_rect, Color.TRANSPARENT)
			# DO NOT just fill rect, selection might have different shapes.
			image.blit_rect_mask(
				_tmp, mask, transform_rect, transform_rect.position)
		
		changed.emit(transform_rect)
		queue_redraw()
		
	visible = true


func cancel():
	reset()


func apply():
	if is_transforming:
		transform_image.resize(transform_rect.size.x, 
							   transform_rect.size.y,
							   Image.INTERPOLATE_NEAREST)
		# DO NOT just fill rect, selection might have different shapes.
		var img_rect = Rect2i(Vector2i.ZERO, transform_rect.size)
		image.blit_rect_mask(transform_image, transform_image,
							 img_rect, transform_rect.position)
		changed.emit(transform_rect)
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


func _draw():
	if visible and is_transforming:
#		texture = ImageTexture.create_from_image(image)
		# DO NOT `var a new texture here, may got blank texture. do it before.
		draw_texture_rect(transform_texture, transform_rect, 
						  false, MODULATE_COLOR)
		draw_rect(transform_rect, line_color, false, 1.0 / zoom_ratio)
