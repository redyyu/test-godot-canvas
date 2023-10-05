class_name BaseCel extends RefCounted

# Base class for cel properties.
# The term "cel" comes from "celluloid" (https://en.wikipedia.org/wiki/Cel).

signal texture_updated

var image_texture := ImageTexture.new(): 
	get = get_image_texture

	
# If the cel is linked a ref to the link set Dictionary this cel is in, 
# or null if not linked:
var link_set = null  # { "cels": Array, "hue": float }

var transformed_content: Image  
# Used in transformations (moving, scaling etc with selections)


func _init(_width :int, _height :int):
	pass


func get_image_texture() -> ImageTexture:
	return image_texture


# The content methods deal with the unique content of each cel type. 
# For example, an Image for PixelLayers, or a Dictionary of settings 
# for a procedural layer type, and null for Groups.
# Can be used for linking/unlinking cels, copying, and deleting content.
func get_content():
	return null


# get visual image of this cel
func get_image():
	return Image.new()


func set_content(_content, _texture: ImageTexture = null):
	return


# Can be used to delete the content of the cel with set_content
# (using the old content from get_content as undo data)
func create_empty_content():
	return null


## Can be used for creating copy content for copying cels or unlinking cels
func copy_content():
	return null


func update_texture():
	texture_updated.emit()
	if link_set is Dictionary:
		for cel in link_set.get("cels", []):
			cel.texture_updated.emit()


func _remove():
	pass

