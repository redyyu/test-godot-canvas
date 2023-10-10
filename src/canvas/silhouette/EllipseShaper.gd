class_name EllipseShaper extends BaseShaper


func shaping(pos :Vector2i):
	super.shaping(pos)
	if is_shaping:
		if points.size() > 1:
			# only keep frist points for rectangle.
			points.resize(1)
		points.append(pos) # append last point for rectangle.
		silhouette.shaping_ellipse(points)


func apply():
	print('apply')
#	silhouette.shaped_ellipse()


func cancel():
	silhouette.reset()



func _input(event):
	if event is InputEventKey:
		if Input.is_key_pressed(KEY_ENTER) and \
		   event.is_command_or_control_pressed():
			apply()
		elif Input.is_key_pressed(KEY_ESCAPE):
			cancel()
