extends Resource
# A class for project properties.

class_name Project

signal project_removed
signal project_size_changed
signal project_cel_changed
signal project_frames_added
signal project_cel_swapped
signal project_cel_moved
signal project_layers_swapped
signal project_layers_moved
signal project_layers_removed
signal project_layers_added
signal project_frames_reversed
signal project_frame_swapped
signal project_frame_moved
signal project_frames_removed


const CEL_SIZE = 36

var name := ""
var size := Vector2i.ZERO :
	set = size_changed

var undo_redo :UndoRedo = UndoRedo.new()
var undos :int = 0  ## The number of times we added undo properties
var can_undo :bool = true

var tiles: Tiles
var fill_color :Color = Color(0)
var has_changed :bool = false

# frames and layers Arrays should generally only be modified directly when
# opening/creating a project. When modifying the current project, use
# the add/remove/move/swap_frames/layers methods
var frames: Array[Frame] = []
var layers: Array[BaseLayer] = []
var current_frame := 0
var current_layer := 0
var selected_cels := [[0, 0]]  # Array of Arrays of 2 integers (frame & layer)

var animation_tags :Array[AnimationTag] = []
	
var guides :Array[Guide] = []
var brushes :Array[Image] = []
var reference_images :Array[ReferenceImage] = []
var vanishing_points := []  # Array of Vanishing Points
var fps := 6.0

var selection_map := SelectionMap.new()
var directory_path := ''


func _init(_frames: Array = [], _name = '',  _size = Vector2i(64, 64)):
	frames = _frames
	name = _name if _name else tr("untitled")
	size = _size
	tiles = Tiles.new(size)
	selection_map.copy_from(Image.create(size.x, size.y, false, Image.FORMAT_LA8))

	if OS.get_name() == "Web":
		directory_path = "user://"
	else:
		directory_path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)


func remove():
	undo_redo.free()
	for ri in reference_images:
		ri.queue_free()
		
	for guide in guides:
		guide.queue_free()
		
	for frame in frames:
		for l in layers.size():
			var cel: BaseCel = frame.cels[l]
			cel.on_remove()
	# Prevents memory leak (due to the layers' project reference stopping ref counting from freeing)
	layers.clear()
	project_removed.emit()


func commit_undo():
	if not can_undo:
		return
	undo_redo.undo()


func commit_redo():
	if not can_undo:
		return
	undo_redo.redo()


func new_empty_frame() -> Frame:
	var frame := Frame.new()
	var bottom_layer := true
	for l in layers:  # Create as many cels as there are layers
		var cel := l.new_empty_cel()
		if cel is PixelCel and bottom_layer and fill_color.a > 0:
			cel.image.fill(fill_color)
		frame.cels.append(cel)
		bottom_layer = false
	return frame


func get_current_cel() -> BaseCel:
	return frames[current_frame].cels[current_layer]


func selection_map_changed():
	var image_texture: ImageTexture
	has_selection = !selection_map.is_invisible()
	if has_selection:
		image_texture = ImageTexture.create_from_image(selection_map)

#
#func serialize() -> Dictionary:
#	var layer_data := []
#	for layer in layers:
#		layer_data.append(layer.serialize())
#		layer_data[-1]["metadata"] = _serialize_metadata(layer)
#
#	var tag_data := []
#	for tag in animation_tags:
#		tag_data.append({
#			"name": tag.name,
#			"color": tag.color.to_html(),
#			"from": tag.from,
#			"to": tag.to
#		})
#
#	var guide_data := []
#	for guide in guides:
#		if guide is SymmetryGuide:
#			continue
#		if not is_instance_valid(guide):
#			continue
#		var coords = guide.points[0].x
#		if guide.type == Guide.Types.HORIZONTAL:
#			coords = guide.points[0].y
#
#		guide_data.append({"type": guide.type, "pos": coords})
#
#	var frame_data := []
#	for frame in frames:
#		var cel_data := []
#		for cel in frame.cels:
#			cel_data.append(cel.serialize())
#			cel_data[-1]["metadata"] = _serialize_metadata(cel)
#
#		frame_data.append(
#			{"cels": cel_data, "duration": frame.duration, "metadata": _serialize_metadata(frame)}
#		)
#	var brush_data := []
#	for brush in brushes:
#		brush_data.append({"size_x": brush.get_size().x, "size_y": brush.get_size().y})
#
#	var reference_image_data := []
#	for reference_image in reference_images:
#		reference_image_data.append(reference_image.serialize())
#
#	var metadata := _serialize_metadata(self)
#
#	var project_data := {
#		"size_x": size.x,
#		"size_y": size.y,
#		"tile_mode_x_basis_x": tiles.x_basis.x,
#		"tile_mode_x_basis_y": tiles.x_basis.y,
#		"tile_mode_y_basis_x": tiles.y_basis.x,
#		"tile_mode_y_basis_y": tiles.y_basis.y,
#		"save_path": '',
#		"layers": layer_data,
#		"tags": tag_data,
#		"guides": guide_data,
##		"symmetry_points": [x_symmetry_point, y_symmetry_point],
#		"frames": frame_data,
#		"brushes": brush_data,
#		"reference_images": reference_image_data,
#		"vanishing_points": vanishing_points,
#		"export_directory_path": directory_path,
#		"export_file_name": file_name,
#		"export_file_format": file_format,
#		"fps": fps,
#		"metadata": metadata
#	}
#
#	return project_data


#func deserialize(dict: Dictionary) -> void:
#	if dict.has("size_x") and dict.has("size_y"):
#		size.x = dict.size_x
#		size.y = dict.size_y
#		tiles.tile_size = size
#		selection_map.crop(size.x, size.y)
#	if dict.has("tile_mode_x_basis_x") and dict.has("tile_mode_x_basis_y"):
#		tiles.x_basis.x = dict.tile_mode_x_basis_x
#		tiles.x_basis.y = dict.tile_mode_x_basis_y
#	if dict.has("tile_mode_y_basis_x") and dict.has("tile_mode_y_basis_y"):
#		tiles.y_basis.x = dict.tile_mode_y_basis_x
#		tiles.y_basis.y = dict.tile_mode_y_basis_y
#	if dict.has("save_path"):
#		OpenSave.current_save_paths[Global.projects.find(self)] = dict.save_path
#	if dict.has("frames") and dict.has("layers"):
#		for saved_layer in dict.layers:
#			match int(saved_layer.get("type", Global.LayerTypes.PIXEL)):
#				Global.LayerTypes.PIXEL:
#					layers.append(PixelLayer.new(self))
#				Global.LayerTypes.GROUP:
#					layers.append(GroupLayer.new(self))
#				Global.LayerTypes.THREE_D:
#					layers.append(Layer3D.new(self))
#
#		var frame_i := 0
#		for frame in dict.frames:
#			var cels: Array[BaseCel] = []
#			var cel_i := 0
#			for cel in frame.cels:
#				match int(dict.layers[cel_i].get("type", Global.LayerTypes.PIXEL)):
#					Global.LayerTypes.PIXEL:
#						cels.append(PixelCel.new(Image.new()))
#					Global.LayerTypes.GROUP:
#						cels.append(GroupCel.new())
#					Global.LayerTypes.THREE_D:
#						cels.append(Cel3D.new(size, true))
#				cels[cel_i].deserialize(cel)
#				_deserialize_metadata(cels[cel_i], cel)
#				cel_i += 1
#			var duration := 1.0
#			if frame.has("duration"):
#				duration = frame.duration
#			elif dict.has("frame_duration"):
#				duration = dict.frame_duration[frame_i]
#
#			var frame_class := Frame.new(cels, duration)
#			_deserialize_metadata(frame_class, frame)
#			frames.append(frame_class)
#			frame_i += 1
#
#		# Parent references to other layers are created when deserializing
#		# a layer, so loop again after creating them:
#		for layer_i in dict.layers.size():
#			layers[layer_i].index = layer_i
#			layers[layer_i].deserialize(dict.layers[layer_i])
#			_deserialize_metadata(layers[layer_i], dict.layers[layer_i])
#	if dict.has("tags"):
#		for tag in dict.tags:
#			animation_tags.append(AnimationTag.new(tag.name, Color(tag.color), tag.from, tag.to))
#		animation_tags = animation_tags
#	if dict.has("guides"):
#		for g in dict.guides:
#			var guide := Guide.new()
#			guide.type = g.type
#			if guide.type == Guide.Types.HORIZONTAL:
#				guide.add_point(Vector2(-99999, g.pos))
#				guide.add_point(Vector2(99999, g.pos))
#			else:
#				guide.add_point(Vector2(g.pos, -99999))
#				guide.add_point(Vector2(g.pos, 99999))
#			guide.has_focus = false
#			guide.project = self
#			Global.canvas.add_child(guide)
#	if dict.has("reference_images"):
#		for g in dict.reference_images:
#			var ri := ReferenceImage.new()
#			ri.project = self
#			ri.deserialize(g)
#			Global.canvas.add_child(ri)
#	if dict.has("vanishing_points"):
#		vanishing_points = dict.vanishing_points
#		Global.perspective_editor.queue_redraw()
#	if dict.has("symmetry_points"):
#		x_symmetry_point = dict.symmetry_points[0]
#		y_symmetry_point = dict.symmetry_points[1]
#		for point in x_symmetry_axis.points.size():
#			x_symmetry_axis.points[point].y = floorf(y_symmetry_point / 2 + 1)
#		for point in y_symmetry_axis.points.size():
#			y_symmetry_axis.points[point].x = floorf(x_symmetry_point / 2 + 1)
#	if dict.has("export_directory_path"):
#		directory_path = dict.export_directory_path
#	if dict.has("export_file_name"):
#		file_name = dict.export_file_name
#	if dict.has("export_file_format"):
#		file_format = dict.export_file_format
#	if dict.has("fps"):
#		fps = dict.fps
#	_deserialize_metadata(self, dict)


#func _serialize_metadata(object: Object) -> Dictionary:
#	var metadata := {}
#	for meta in object.get_meta_list():
#		metadata[meta] = object.get_meta(meta)
#	return metadata
#
#
#func _deserialize_metadata(object: Object, dict: Dictionary) -> void:
#	if not dict.has("metadata"):
#		return
#	var metadata: Dictionary = dict["metadata"]
#	for meta in metadata.keys():
#		object.set_meta(meta, metadata[meta])


func size_changed(value: Vector2i):
	if not is_instance_valid(tiles):
		size = value
		return
	if size.x != 0:
		tiles.x_basis = tiles.x_basis * value.x / size.x
	else:
		tiles.x_basis = Vector2i(value.x, 0)
	if size.y != 0:
		tiles.y_basis = tiles.y_basis * value.y / size.y
	else:
		tiles.y_basis = Vector2i(0, value.y)
	tiles.tile_size = value
	size = value
	project_size_changed.emit()


func change_cel(new_frame: int, new_layer := -1):
	if new_frame < 0:
		new_frame = current_frame
	if new_layer < 0:
		new_layer = current_layer

	if selected_cels.is_empty():
		selected_cels.append([new_frame, new_layer])
	for cel in selected_cels:  # Press selected buttons
		var frame: int = cel[0]
		var layer: int = cel[1]

	if new_frame != current_frame:  # If the frame has changed
		current_frame = new_frame

	if new_layer != current_layer:  # If the layer has changed
		current_layer = new_layer

	if current_frame < frames.size():  # Set opacity slider
		var cel_opacity: float = frames[current_frame].cels[current_layer].opacity
	
	project_cel_changed.emit()


func is_empty() -> bool:
	return (
		frames.size() == 1
		and layers.size() == 1
		and layers[0] is PixelLayer
		and frames[0].cels[0].image.is_invisible()
		and animation_tags.size() == 0
	)


func can_pixel_get_drawn(pixel: Vector2i, 
						 image: SelectionMap, 
						 selection_position: Vector2i) -> bool:
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= size.x or pixel.y >= size.y:
		return false

	if tiles.mode != Tiles.MODE.NONE and !tiles.has_point(pixel):
		return false

	if has_selection:
		if selection_position.x < 0:
			pixel.x -= selection_position.x
		if selection_position.y < 0:
			pixel.y -= selection_position.y
		return image.is_pixel_selected(pixel)
	else:
		return true


# Timeline modifications
# Modifying layers or frames Arrays on the current project should generally only be done
# through these methods.
# These allow you to add/remove/move/swap frames/layers/cels. It updates the Animation Timeline
# UI, and updates indices. These are designed to be reversible, meaning that to undo an add, you
# use remove, and vice versa. To undo a move or swap, use move or swap with the parameters swapped.


func add_frames(new_frames: Array, indices: Array):  # indices should be in ascending order
	selected_cels.clear()
	for i in new_frames.size():
		# For each linked cel in the frame, update its layer's cel_link_sets
		for l in layers.size():
			var cel: BaseCel = new_frames[i].cels[l]
			if cel.link_set != null:
				if not layers[l].cel_link_sets.has(cel.link_set):
					layers[l].cel_link_sets.append(cel.link_set)
				cel.link_set["cels"].append(cel)
		# Add frame
		frames.insert(indices[i], new_frames[i])
	
	project_frames_added.emit()


func remove_frames(indices: Array):  # indices should be in ascending order
	selected_cels.clear()
	for i in indices.size():
		# With each removed index, future indices need to be lowered, so subtract by i
		# For each linked cel in the frame, update its layer's cel_link_sets
		for l in layers.size():
			var cel: BaseCel = frames[indices[i] - i].cels[l]
			cel.on_remove()
			if cel.link_set != null:
				cel.link_set["cels"].erase(cel)
				if cel.link_set["cels"].is_empty():
					layers[l].cel_link_sets.erase(cel.link_set)
		# Remove frame
		frames.remove_at(indices[i] - i)
	project_frames_removed.emit()


func move_frame(from_index: int, to_index: int):
	selected_cels.clear()
	var frame := frames[from_index]
	frames.remove_at(from_index)
	frames.insert(to_index, frame)
	project_frame_moved.emit()


func swap_frame(a_index: int, b_index: int):
	selected_cels.clear()
	var temp := frames[a_index]
	frames[a_index] = frames[b_index]
	frames[b_index] = temp
	project_frame_swapped.emit()


func reverse_frames(frame_indices: Array):
	var frame_indices_size = frame_indices.size() / 2.0
	for i in frame_indices_size:
		var index: int = frame_indices[i]
		var reverse_index: int = frame_indices[-i - 1]
		var temp := frames[index]
		frames[index] = frames[reverse_index]
		frames[reverse_index] = temp
	change_cel(-1)
	project_frames_reversed.emit()


func add_layers(new_layers: Array, indices: Array, cels: Array):
	# cels is 2d Array of cels
	selected_cels.clear()
	for i in indices.size():
		layers.insert(indices[i], new_layers[i])
		for f in frames.size():
			frames[f].cels.insert(indices[i], cels[i][f])
		new_layers[i].project = self
	
	project_layers_added.emit()	
	

func remove_layers(indices: Array):
	selected_cels.clear()
	for i in indices.size():
		# With each removed index, future indices need to be lowered, so subtract by i
		layers.remove_at(indices[i] - i)
		for frame in frames:
			frame.cels[indices[i] - i].on_remove()
			frame.cels.remove_at(indices[i] - i)
	project_layers_removed.emit()


# from_indices and to_indicies should be in ascending order
func move_layers(from_indices: Array, to_indices: Array, to_parents: Array):
	selected_cels.clear()
	var removed_layers := []
	var removed_cels := []  # 2D array of cels (an array for each layer removed)

	for i in from_indices.size():
		# With each removed index, future indices need to be lowered, so subtract by i
		removed_layers.append(layers.pop_at(from_indices[i] - i))
		removed_layers[i].parent = to_parents[i]  # parents must be set before UI created in next loop
		removed_cels.append([])
		for frame in frames:
			removed_cels[i].append(frame.cels.pop_at(from_indices[i] - i))
	for i in to_indices.size():
		layers.insert(to_indices[i], removed_layers[i])
		for f in frames.size():
			frames[f].cels.insert(to_indices[i], removed_cels[i][f])
	
	project_layers_moved.emit()
	

# "a" and "b" should both contain "from", "to", and "to_parents" arrays.
# (Using dictionaries because there seems to be a limit of 5 arguments for do/undo method calls)
func swap_layers(a: Dictionary, b: Dictionary):
	selected_cels.clear()
	var a_layers := []
	var b_layers := []
	var a_cels := []  # 2D array of cels (an array for each layer removed)
	var b_cels := []  # 2D array of cels (an array for each layer removed)
	for i in a.from.size():
		a_layers.append(layers.pop_at(a.from[i] - i))
		a_layers[i].parent = a.to_parents[i]  # All parents must be set early, before creating buttons
		a_cels.append([])
		for frame in frames:
			a_cels[i].append(frame.cels.pop_at(a.from[i] - i))
	for i in b.from.size():
		var index = (b.from[i] - i) if a.from[0] > b.from[0] else (b.from[i] - i - a.from.size())
		b_layers.append(layers.pop_at(index))
		b_layers[i].parent = b.to_parents[i]  # All parents must be set early, before creating buttons
		b_cels.append([])
		for frame in frames:
			b_cels[i].append(frame.cels.pop_at(index))

	for i in a_layers.size():
		var index = a.to[i] if a.to[0] < b.to[0] else (a.to[i] - b.to.size())
		layers.insert(index, a_layers[i])
		for f in frames.size():
			frames[f].cels.insert(index, a_cels[i][f])
	for i in b_layers.size():
		layers.insert(b.to[i], b_layers[i])
		for f in frames.size():
			frames[f].cels.insert(b.to[i], b_cels[i][f])
	project_layers_swapped.emit()


func move_cel(from_frame: int, to_frame: int, layer: int):
	selected_cels.clear()
	var cel: BaseCel = frames[from_frame].cels[layer]
	if from_frame < to_frame:
		for f in range(from_frame, to_frame):  # Forward range
			frames[f].cels[layer] = frames[f + 1].cels[layer]  # Move left
	else:
		for f in range(from_frame, to_frame, -1):  # Backward range
			frames[f].cels[layer] = frames[f - 1].cels[layer]  # Move right
	frames[to_frame].cels[layer] = cel
	project_cel_moved.emit()


func swap_cel(a_frame: int, a_layer: int, b_frame: int, b_layer: int):
	selected_cels.clear()
	var temp := frames[a_frame].cels[a_layer]
	frames[a_frame].cels[a_layer] = frames[b_frame].cels[b_layer]
	frames[b_frame].cels[b_layer] = temp
	project_cel_swapped.emit()
