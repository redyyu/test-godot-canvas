class_name OnionSkinning extends Node2D

enum OnionType { 
	PAST,
	FUTURE
}

@export var type :OnionType = OnionType.PAST

var color :Color = Color.BLUE
var rate :float = 1.0
var skinning :bool = false
var mirror_view :bool = false

var project_size :Vector2 = Vector2.ZERO
var current_frame :int = 0
var project_frames :Array = []
var layers :Array = []
var selected_cels
var move_preview_location


func _draw() -> void:
	if not skinning:
		return

	if rate <= 0:
		return

	var position_tmp :Vector2 = position
	var scale_tmp = scale
	if mirror_view:
		position_tmp.x += project_size.x
		scale_tmp.x = -1
	draw_set_transform(position_tmp, rotation, scale_tmp)

	for i in range(1, rate + 1):
		var change :int = current_frame
		
		if type == OnionType.FUTURE:
			change += i
		else:
			change -= i
		
		if change == clamp(change, 0, project_frames.size() - 1):
			var layer_i := 0
			for cel in project_frames[change].cels:
				var layer: BaseLayer = layers[layer_i]
				if layer.is_visible_in_hierarchy():
					if not (layer.name.to_lower().ends_with("_io")):
						color.a = 0.6 / i
						if [change, layer_i] in selected_cels:
							draw_texture(cel.image_texture, 
										 move_preview_location, 
										 color)
						else:
							draw_texture(cel.image_texture, Vector2.ZERO, color)
				layer_i += 1
	draw_set_transform(position, rotation, scale)
