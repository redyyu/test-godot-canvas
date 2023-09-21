class_name PixelLayer
## A class for standard pixel layer properties.

extends BaseLayer


var type := LayerTypes.PIXEL
var opacity := 1.0


# Overridden Methods:
func new_empty_cel(width :int, height: int) -> PixelCel:
	return PixelCel.new(width, height, opacity)


func can_layer_get_drawn() -> bool:
	return is_visible_in_hierarchy() && !is_locked_in_hierarchy()
