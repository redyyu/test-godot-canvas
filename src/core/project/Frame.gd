class_name Frame extends RefCounted
# A class for frame properties.
# A frame is a collection of cels, for each layer.

var cels: Array[BaseCel]
var duration := 1.0


func append_cel(cel :BaseCel):
	cels.append(cel)
	

func erase_cel(cel :BaseCel):
	if cels.has(cel):
		cels.erase(cel)


func get_images():
	var images := []
	for cel in cels:
		if cel is PixelCel:
			var img :Image = cel.get_image()
			if not img.is_empty() and not img.is_invisible():
				images.append(cel.get_image())
	return images
