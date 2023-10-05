class_name PixelCel extends BaseCel
# A class for the properties of cels in PixelLayers.
# The term "cel" comes from "celluloid" (https://en.wikipedia.org/wiki/Cel).

var width := 0
var height := 0

var image :Image :
	set = set_image


func _init(_width :int, _height :int):
	width = _width
	height = _height
	
	image = Image.create(width, height, true, Image.FORMAT_RGBA8)
#	image_texture = ImageTexture.create_from_image(image)
#	# image's setter will take care of it.
	

func set_image(value: Image):
	image = value
	update_texture()


func get_image():
	# for pixel cel it is same with `get_content`,
	# the reason make two same func is for future other type Cel class.
	# generally, `get_image` is for get the visual of this cel,
	# ex., for a 3DCel, content might be 3D mesh, 
	# but still need a image to rendering.
	return image


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
	if image.is_empty():
		image_texture = ImageTexture.new()
	else:
		image_texture.set_image(image)
	super.update_texture()
