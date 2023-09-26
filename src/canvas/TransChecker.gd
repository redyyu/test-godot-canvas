extends ColorRect

var checker_size := 10.0 :
	set(val):
		checker_size = val
		material.set_shader_parameter("size", checker_size)

var color_1 := Color.GRAY :
	set(val):
		color_1 = val
		material.set_shader_parameter("color1", color_1)
		
var color_2 := Color.TRANSPARENT :
	set(val):
		color_2 = val
		material.set_shader_parameter("color2", color_2)
	
var follow_movement := false :
	set(val):
		follow_movement = val
		material.set_shader_parameter("follow_movement", follow_movement)
			
var follow_scale := false :
	set(val):
		follow_scale = val
		material.set_shader_parameter("follow_scale", follow_scale)
			
var offset := Vector2.ZERO :
	set(val):
		offset = val
		material.set_shader_parameter("offset", offset)
		
var canvas_scale := Vector2.ZERO :
	set(val):
		canvas_scale = val
		material.set_shader_parameter("scale", canvas_scale)


func _ready():
	resized.connect(_on_resized)
	

func update_bounds(bounds_size :Vector2i):
	# Set the size to be the same as the project size.
	set_bounds(bounds_size)
#	refresh()


func set_bounds(bounds: Vector2) -> void:
	offset_right = bounds.x
	offset_bottom = bounds.y
#
#
func fit_rect(rect: Rect2) -> void:
	offset_left = rect.position.x
	offset_right = rect.position.x + rect.size.x
	offset_top = rect.position.y
	offset_bottom = rect.position.y + rect.size.y


func _on_resized():
	material.set_shader_parameter("rect_size", size)
