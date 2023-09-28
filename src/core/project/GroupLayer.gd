class_name GroupLayer extends BaseLayer
## A class for group layer properties

var type := LayerTypes.GROUP


func get_children(layers :Array[BaseLayer], recursive: bool) -> Array:
	var children: Array[BaseLayer] = []
	if recursive:
		for i in index:
			if is_ancestor_of(layers[i]):
				children.append(layers[i])
	else:
		for i in index:
			if layers[i].parent == self:
				children.append(layers[i])
	return children


# Blends all of the images of children layer 
# of the group layer into a single image.
func blend_children(frame: Frame, layers :Array[BaseLayer], size:Vector2i,
					origin := Vector2i.ZERO) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var children := get_children(layers, false)
	var blend_rect := Rect2i(Vector2i.ZERO, size)
	for layer in children:
		if not layer.is_visible_in_hierarchy():
			continue
		if layer is GroupLayer:
			image.blend_rect(layer.blend_children(frame, origin), 
							 blend_rect,
							 origin)
		else:
			var cel := frame.cels[layer.index]
			var cel_image := Image.new()
			cel_image.copy_from(cel.get_image())
			if cel.opacity < 1.0:  # If we have cel transparency
				for xx in cel_image.get_size().x:
					for yy in cel_image.get_size().y:
						var pixel_color := cel_image.get_pixel(xx, yy)
						pixel_color.a *= cel.opacity
						cel_image.set_pixel(xx, yy, pixel_color)
			image.blend_rect(cel_image, blend_rect, origin)
	return image


# Overridden Methods:
func set_name_to_default(number: int) -> void:
	name = tr("Group") + " %s" % number


func can_layer_get_drawn() -> bool:
	return false
