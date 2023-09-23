extends BaseCel

class_name PixelCel
# A class for the properties of cels in PixelLayers.
# The term "cel" comes from "celluloid" (https://en.wikipedia.org/wiki/Cel).

var width := 0
var height := 0

var image :Image :
	set = image_changed


func _init(_width :int, _height :int):
	width = _width
	height = _height
	
	image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image_texture = ImageTexture.create_from_image(image)
	

func image_changed(value: Image):
	image = value
	if !image.is_empty():
		image_texture.set_image(image)


func get_content():
	return image


func set_content(content: Image, texture: ImageTexture = null):
	image = content
	if is_instance_valid(texture):
		image_texture = texture
		if image_texture.get_image().get_size() != image.get_size():
			image_texture = ImageTexture.create_from_image(image)


func create_empty_content():
	var empty_image := Image.create(
		image.get_size().x, image.get_size().y, false, Image.FORMAT_RGBA8
	)
	return empty_image


func copy_content():
	var copy_image := Image.create_from_data(
		image.get_width(),
		image.get_height(), 
		false,
		Image.FORMAT_RGBA8,
		image.get_data()
	)
	return copy_image


func update_texture():
	image_texture.set_image(image)
	super.update_texture()
