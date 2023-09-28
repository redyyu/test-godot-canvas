class_name Project extends Resource

const CEL_SIZE = 36

var name := ""
var size := Vector2i.ZERO :
	set = change_size

var undo_redo :UndoRedo = UndoRedo.new()
var undos :int = 0  ## The number of times we added undo properties
var can_undo :bool = true

var tiles: Tiles
var fill_color :Color = Color.BLACK

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

var selected_cels := [[0, 0]]  # Arrays of 2 integers (frame & layer)

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
	
	add_empty_frame()
	create_pixel_layer()
	
	if OS.get_name() == "Web":
		save_dir_path = "user://"
		export_dir_path = "user://"


func remove():
	undo_redo.free()
	for ri in reference_images:
		ri.queue_free()
		
	for frame in frames:
		for l in layers.size():
			var cel: BaseCel = frame.cels[l]
			cel.on_remove()
	# Prevents memory leak (due to the layers' project 
	# reference stopping ref counting from freeing)
	layers.clear()


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


func is_empty() -> bool:
	return (
		frames.size() <= 1
		and layers.size() <= 1
		and layers[0] is PixelLayer
		and frames[0].cels[0].image.is_invisible()
		and animation_tags.size() == 0
	)


#func can_pixel_get_drawn(pixel: Vector2i, 
#						 image: SelectionMap, 
#						 selection_position: Vector2i) -> bool:
#
#	if pixel.x < 0 or pixel.y < 0 or pixel.x >= size.x or pixel.y >= size.y:
#		return false
#
##	if tiles.mode != Tiles.MODE.NONE and !tiles.has_point(pixel):
##		return false
#
#	if selection_position != Vector2i.ZERO:
#		if selection_position.x < 0:
#			pixel.x -= selection_position.x
#		if selection_position.y < 0:
#			pixel.y -= selection_position.y
#		return image.is_pixel_selected(pixel)
#	else:
#		return true


# Timeline modifications
# These allow you to add/remove/move/swap frames/layers/cels.

# layers

func create_pixel_layer(index := 0) -> PixelLayer:
	var layer = PixelLayer.new()
	for f in frames.size():
		var cel = layer.new_empty_cel(size)
		frames[f].cels.insert(index, cel)
	layers.insert(index, layer)
	return layer


func remove_layer(index):
	layers.remove_at(index)
	for frame in frames:
		frame.cels.remove_at(index)
			

func remove_layers(indices: Array):
	indices.sort() # sort to ascending
	indices.reverse() # reverse to descending.
	# remove largest index first, 
	# otherwise the index order will be change while in the loop.
	for i in indices:  
		remove_layer(i)


# from_indices and to_indicies should be in ascending order
func move_layer(from_index: int, to_index: int, to_parent :GroupLayer = null):
	var moved_cels := []
	var moved_layer = layers.pop_at(from_index)
	
	moved_layer.parent = to_parent if to_parent != moved_layer else null
	for frame in frames:
		moved_cels.append(frame.cels.pop_at(from_index))
	
	layers.insert(to_index, moved_layer)
	for f in frames.size():
		frames[f].cels.insert(to_index, moved_cels[f])


func move_layers(from_indices :Array[int], to_index: int,
				 to_parent :GroupLayer = null):
	from_indices.sort()
	from_indices.reverse()
	for i in from_indices.size():
		var from_index = from_indices[i]
		move_layer(from_index, to_index, to_parent)
		# to_index is same, because they should sort togehter after moved.
		

# frames
func add_empty_frame(index :=0) -> Frame:
	var frame := Frame.new()
	var bottom_layer := true
	for l in layers:  # Create as many cels as there are layers
		var cel = l.new_empty_cel()
		if cel is PixelCel and bottom_layer and fill_color.a > 0:
			cel.image.fill(fill_color)
		frame.append_cel(cel)
		bottom_layer = false
	frames.insert(index, frame)
	return frame


func remove_frame(index :int):
	for l in layers.size():
		var cel: BaseCel = frames[index].cels[l]
		if cel.link_set != null:
			cel.link_set["cels"].erase(cel)
			if cel.link_set["cels"].is_empty():
				layers[l].cel_link_sets.erase(cel.link_set)
	# Remove frame
	frames.remove_at(index)


func remove_frames(indices: Array):  # indices should be in ascending order
	indices.sort()
	
	for i in indices.size():
		remove_frame(indices[i] - i)
		# With each removed index, future indices need to be lowered,
		# so subtract by i. should work in this case either.
		# that will also make sure the rmeove index is match the changes.


func move_frame(from_index: int, to_index: int):
	var frame := frames[from_index]
	frames.remove_at(from_index)
	frames.insert(to_index, frame)


func swap_frame(a_index: int, b_index: int):
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


# cel
func move_cel(from_frame: int, to_frame: int, layer: int):
	# can only move cel with same layer.
	# because other move form layer will getting extra cels for the layer.
	# leave that for now, until figure out a good idea to cover this.
	var temp: = frames[from_frame].cels[layer]
	if from_frame < to_frame:
		for f in range(from_frame, to_frame):  # Forward range
			frames[f].cels[layer] = frames[f + 1].cels[layer]  # Move left
	else:
		for f in range(from_frame, to_frame, -1):  # Backward range
			frames[f].cels[layer] = frames[f - 1].cels[layer]  # Move right
	frames[to_frame].cels[layer] = temp


func swap_cel(a_frame: int, a_layer: int, b_frame: int, b_layer: int):
	var temp := frames[a_frame].cels[a_layer]
	frames[a_frame].cels[a_layer] = frames[b_frame].cels[b_layer]
	frames[b_frame].cels[b_layer] = temp
