extends Sprite2D

class_name ReferenceImage
# A class describing a reference image

signal reference_updated

var alpha := 0.6:
	set(val):
		alpha = clamp(val, 0.2, 0.8)
		modulate = Color(1, 1, 1, alpha)		

var size := Vector2i.ZERO


func _ready():
#	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	

## Resets the position and scale of the reference image.
func position_reset():
	position = size * 0.5
	if texture:
		scale = (
			Vector2.ONE
			* minf(
				float(size.x) / texture.get_width(),
				float(size.y) / texture.get_height()
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
