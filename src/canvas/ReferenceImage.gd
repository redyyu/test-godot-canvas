class_name ReferenceImage extends Sprite2D
# A class describing a reference image

signal reference_updated

var alpha := 0.6:
	set(val):
		alpha = clamp(val, 0.2, 0.8)
		modulate = Color(1, 1, 1, alpha)		

var canvas_size := Vector2i.ZERO:
	set(val):
		canvas_size = val
		position_reset()


func _ready():
#	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	

## Resets the position and scale of the reference image.
func position_reset():
	position = canvas_size * 0.5
	if texture:
		scale = (
			Vector2.ONE
			* minf(
				float(canvas_size.x) / texture.get_width(),
				float(canvas_size.y) / texture.get_height()
			)
		)
	else:
		scale = Vector2.ONE


func set_image(img: Image):
	if img.is_empty():
		return
	modulate = Color(1, 1, 1, alpha)
	# Note that reference images are referred to by path.
	# These images may be rather big.
	texture = ImageTexture.create_from_image(img)

	# Now that the image may have been established...
	position_reset()
	reference_updated.emit()
	show()
	
	
func remove_image():
	# Note that reference images are referred to by path.
	# These images may be rather big.
	texture = null
	reference_updated.emit()
	hide()
