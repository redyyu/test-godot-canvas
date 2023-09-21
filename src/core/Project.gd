extends Resource
# A class for project properties.

class_name Project

const CEL_SIZE = 36

var name := ""
var size := Vector2i.ZERO :
	set = change_size

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
var current_frame :Frame :
	get: return frames[current_frame_index]
var current_layer :BaseLayer :
	get: return layers[current_layer_index]
var current_cel :BaseCel :
	get: return frames[current_frame_index].cels[current_layer_index]

var current_frame_index := 0
var current_layer_index := 0

var selected_cels := [[0, 0]]  # Array of Arrays of 2 integers (frame & layer)

var animation_tags :Array[AnimationTag] = []
	
var guides :Array[Guide] = []
var reference_images :Array[ReferenceImage] = []
var vanishing_points := []  # Array of Vanishing Points
var fps := 6.0

var save_dir_path := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
var export_dir_path := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)


func _init(_size := Vector2i(64, 64), _name := tr("untitled")):
	name = _name
	size = _size
	tiles = Tiles.new(size)

	if OS.get_name() == "Web":
		save_dir_path = "user://"
		export_dir_path = "user://"


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
		var cel = l.new_empty_cel()
		if cel is PixelCel and bottom_layer and fill_color.a > 0:
			cel.image.fill(fill_color)
		frame.cels.append(cel)
		bottom_layer = false
	return frame


func save():
	pass


func change_size(value: Vector2i):
	if is_instance_valid(tiles):
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
	else:
		size = value


func change_cel(new_frame_index := -1, new_layer_index := -1):
	if new_frame_index < 0:
		new_frame_index = current_frame_index
	if new_layer_index < 0:
		new_layer_index = current_layer_index

	if selected_cels.is_empty():
		selected_cels.append([new_frame_index, new_layer_index])

	if new_frame_index != current_frame_index:  # If the frame has changed
		current_frame_index = new_frame_index

	if new_layer_index != current_layer_index:  # If the layer has changed
		current_layer_index = new_layer_index


func is_empty() -> bool:
	return (
		frames.size() <= 1
		and layers.size() <= 1
		and layers[0] is PixelLayer
		and frames[0].cels[0].image.is_invisible()
		and animation_tags.size() == 0
	)


func can_pixel_get_drawn(pixel: Vector2i, 
						 image: SelectionMap, 
						 selection_position: Vector2i) -> bool:
	
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= size.x or pixel.y >= size.y:
		return false

#	if tiles.mode != Tiles.MODE.NONE and !tiles.has_point(pixel):
#		return false

	if selection_position != Vector2i.ZERO:
		if selection_position.x < 0:
			pixel.x -= selection_position.x
		if selection_position.y < 0:
			pixel.y -= selection_position.y
		return image.is_pixel_selected(pixel)
	else:
		return true


# Timeline modifications
# These allow you to add/remove/move/swap frames/layers/cels.

func add_frames(new_frames: Array, indices: Array):
	# indices should be in ascending order
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


func move_frame(from_index: int, to_index: int):
	selected_cels.clear()
	var frame := frames[from_index]
	frames.remove_at(from_index)
	frames.insert(to_index, frame)


func swap_frame(a_index: int, b_index: int):
	selected_cels.clear()
	var temp := frames[a_index]
	frames[a_index] = frames[b_index]
	frames[b_index] = temp


func reverse_frames(frame_indices: Array):
	var frame_indices_size = frame_indices.size() / 2.0
	for i in frame_indices_size:
		var index: int = frame_indices[i]
		var reverse_index: int = frame_indices[-i - 1]
		var temp := frames[index]
		frames[index] = frames[reverse_index]
		frames[reverse_index] = temp
	change_cel()


func add_layers(new_layers: Array, indices: Array, cels: Array):
	# cels is 2d Array of cels
	selected_cels.clear()
	for i in indices.size():
		layers.insert(indices[i], new_layers[i])
		for f in frames.size():
			frames[f].cels.insert(indices[i], cels[i][f])
	

func remove_layers(indices: Array):
	selected_cels.clear()
	for i in indices.size():
		# With each removed index, future indices need to be lowered, so subtract by i
		layers.remove_at(indices[i] - i)
		for frame in frames:
			frame.cels[indices[i] - i].on_remove()
			frame.cels.remove_at(indices[i] - i)


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


func swap_cel(a_frame: int, a_layer: int, b_frame: int, b_layer: int):
	selected_cels.clear()
	var temp := frames[a_frame].cels[a_layer]
	frames[a_frame].cels[a_layer] = frames[b_frame].cels[b_layer]
	frames[b_frame].cels[b_layer] = temp
