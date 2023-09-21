class_name ReferenceImage
# A class describing a reference image

extends Sprite2D

signal reference_updated

var shader = preload("res://src/Shaders/SilhouetteShader.gdshader")

var image_path = ""

var image_size :Vector2i = Vector2i.ZERO

var filter = false
var silhouette = false


func _ready():
	pass


## Resets the position and scale of the reference image.
func position_reset():
	position = image_size / 2.0
	if texture:
		scale = (
			Vector2.ONE
			* minf(
				float(image_size.x) / texture.get_width(),
				float(image_size.y) / texture.get_height()
			)
		)
	else:
		scale = Vector2.ONE


func set_reference(_path := ''):
	modulate = Color(1, 1, 1, 0.5)
	if _path:
		image_path = _path
		# Note that reference images are referred to by path.
		# These images may be rather big.
		var img := Image.new()
		if img.load(image_path) == OK:
			var itex := ImageTexture.create_from_image(img)
			texture = itex
			image_size = Vector2i(img.get_width(), img.get_height())
		# Apply the silhouette shader
		var mat := ShaderMaterial.new()
		mat.shader = shader
		# TODO: Lsbt - Add a option in prefrences to customize the color
		# This color is almost black because it is less harsh
		mat.set_shader_parameter("silhouette_color", Color(0.069, 0.069326, 0.074219))
		set_material(mat)

	# Now that the image may have been established...
	position_reset()
	reference_updated.emit()


## Useful for Web
func create_from_image(image: Image) -> void:
	texture = ImageTexture.create_from_image(image)
	position_reset()
