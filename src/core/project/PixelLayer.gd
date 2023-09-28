class_name PixelLayer extends BaseLayer
## A class for standard pixel layer properties.

var type := LayerTypes.PIXEL


# Overridden Methods:
func new_empty_cel(size:Vector2i) -> PixelCel:
	return PixelCel.new(size.x, size.y)


func can_layer_get_drawn() -> bool:
	return is_visible_in_hierarchy() && !is_locked_in_hierarchy()
