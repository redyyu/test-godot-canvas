extends Node2D

var indicator_position := Vector2i.ZERO
var indicator_size := Vector2i.ONE
var indicator_offset := Vector2i.ZERO
var indicator_color :=  Color(0.6, 0.33, 0.26, 0.66)


func _draw():
	if visible:
		draw_indicator()


func draw_indicator():
	var pos = indicator_position - indicator_offset
	var rect = Rect2i(pos, indicator_size)
	draw_rect(rect, indicator_color, false)

#
#func draw_line_indicator():
#	if _draw_line:
#		pos.x = _line_end.x if _line_end.x < _line_start.x else _line_start.x
#		pos.y = _line_end.y if _line_end.y < _line_start.y else _line_start.y
#	pos -= _indicator.get_size() / 2
#	pos -= offset
#	canvas.draw_set_transform(pos, canvas.rotation, canvas.scale)
#	var polylines := _line_polylines if _draw_line else _polylines
#	for line in polylines:
#		var pool := PackedVector2Array(line)
#		canvas.draw_polyline(pool, color)
#	canvas.draw_set_transform(canvas.position, canvas.rotation, canvas.scale)
