extends Node

class_name Export

const SEPARATOR_CHARACTER := "_"
const NUM_OF_DIGITS := 6

enum ExportType { IMAGE = 0, SPRITESHEET = 1 }
enum Orientation { ROWS = 0, COLUMNS = 1 }
enum Direction { FORWARD = 0, BACKWARDS = 1, PING_PONG = 2 }

enum FileFormat { PNG = 0, GIF = 1, APNG = 2 }

# List of animated formats
var animated_formats := [FileFormat.GIF, FileFormat.APNG]

var current_tab := ExportType.IMAGE
# All frames and their layers processed/blended into images
var processed_images: Array[Image] = []
var durations: PackedFloat32Array = []

# Spritesheet options
var orientation := Orientation.ROWS
var lines_count := 1  # How many rows/columns before new line is added

# General options
enum ExportFrame {
	ALL_FRAMES,
	SELECTED_FRAMES,
	FRAME_TAG,
}
enum ExportLayer {
	ALL_LAYERS,
	SELECTED_LAYERS,
}
var export_frame_type := ExportFrame.ALL_FRAMES
var export_layer_type := ExportLayer.ALL_LAYERS

var export_frame_tag_index := 0

var export_direction := Direction.FORWARD
var number_of_frames := 1
var resize := 100
var interpolation := Image.INTERPOLATE_NEAREST
var include_tag_in_filename := false
var new_dir_for_each_frame_tag := false  # We don't need to store this after export

var stop_export := false  # Export coroutine signal

# Export progress variables

var export_as_animation : bool :
	get: return animated_formats.has(export_file_format)
	
var export_file_format := FileFormat.PNG

var export_file_ext :String :
	get: return file_format_string(export_file_format)
	
var export_file_name :String :
	get: 
		return '{name}.{ext}'.format({
			'name': project.name if project else '-',
			'ext': export_file_ext,
		})

var project: Project

@onready var gif_export_thread := Thread.new()


func _init(proj: Project):
	project = proj
	

func _exit_tree():
	if gif_export_thread.is_started():
		gif_export_thread.wait_to_finish()


func external_export():
	match current_tab:
		ExportType.IMAGE:
			process_animation()
		ExportType.SPRITESHEET:
			process_spritesheet()
	export_processed_images()


func process_spritesheet():
	if not project:
		return
	processed_images.clear()
	# Range of frames determined by tags
	var frames := calculate_frames()
	# Then store the size of frames for other functions
	number_of_frames = frames.size()

	# If rows mode selected calculate columns count and vice versa
	var spritesheet_columns := (lines_count if orientation == Orientation.ROWS
								else frames_divided_by_spritesheet_lines())
	var spritesheet_rows := (lines_count if orientation == Orientation.COLUMNS
							 else frames_divided_by_spritesheet_lines())

	var width := project.size.x * spritesheet_columns
	var height := project.size.y * spritesheet_rows

	var whole_image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var origin := Vector2i.ZERO
	var hh := 0
	var vv := 0

	for frame in frames:
		if orientation == Orientation.ROWS:
			if vv < spritesheet_columns:
				origin.x = project.size.x * vv
				vv += 1
			else:
				hh += 1
				origin.x = 0
				vv = 1
				origin.y = project.size.y * hh
		else:
			if hh < spritesheet_rows:
				origin.y = project.size.y * hh
				hh += 1
			else:
				vv += 1
				origin.y = 0
				hh = 1
				origin.x = project.size.x * vv
		blend_layers(whole_image, frame, origin)

	processed_images.append(whole_image)


func process_animation():
	processed_images.clear()
	durations.clear()
	var frames := calculate_frames()
	for frame in frames:
		var image := Image.create(project.size.x, project.size.y, false, Image.FORMAT_RGBA8)
		blend_layers(image, frame, Vector2i.ZERO)
		processed_images.append(image)
		durations.append(frame.duration * (1.0 / project.fps))


func calculate_frames() -> Array[Frame]:
	var frames: Array[Frame] = []
	
	match export_frame_type:
		ExportFrame.ALL_FRAMES:
			frames = project.frames.duplicate()
		ExportFrame.SELECTED_FRAMES:
			for cel in project.selected_cels:
				frames.append(project.frames[cel[0]])
		ExportFrame.FRAME_TAG:
			var frame = project.animation_tags[export_frame_tag_index]
			frames = project.frames.slice(frame.from - 1, frame.to - 1, 1, true)	

	if export_direction == Direction.BACKWARDS:
		frames.reverse()
	elif export_direction == Direction.PING_PONG:
		var inverted_frames := frames.duplicate()
		inverted_frames.reverse()
		inverted_frames.remove_at(0)
		frames.append_array(inverted_frames)
		
	return frames


func export_processed_images(ignore_overwrites: bool=false) -> bool:
	# Stop export if directory path or file name are not valid
	var dir := DirAccess.open(project.directory_path)
	
	if not dir or not export_file_name:
		return false

	var multiple_files := false
	if current_tab == ExportType.IMAGE and not export_as_animation:
		multiple_files = true if processed_images.size() > 1 else false
	
	# Check export paths
	var export_paths: PackedStringArray = []
	var paths_of_existing_files :PackedStringArray = []
	
	# Only get one export path if single file animated image is exported
	if multiple_files:
		for i in processed_images.size():
			var num = str(i).pad_zeros(NUM_OF_DIGITS)
			var file_name = '{name}.{ext}'.format({
				'name': project.name + SEPARATOR_CHARACTER + num,
				'ext': export_file_ext
			})
			var export_path = project.export_dir_path.path_join(file_name)
			if not ignore_overwrites:
				# Check if the files already exist
				if FileAccess.file_exists(export_path):
					paths_of_existing_files.append(export_path)
			export_paths.append(export_path)
	else:
		export_paths.append(
			project.export_dir_path.path_join(export_file_name))

	# scale images
	for processed_image in processed_images:
		if resize != 100:
			processed_image.resize(
				processed_image.get_size().x * resize / 100.0,
				processed_image.get_size().y * resize / 100.0,
				interpolation
			)

	if multiple_files:
		for i in processed_images.size():
			if OS.has_feature("web"):
				JavaScriptBridge.download_buffer(
					processed_images[i].save_png_to_buffer(),
					export_paths[i].get_file(),
					"image/png"
				)
			else:
				var err := processed_images[i].save_png(export_paths[i])
				if err != OK:
					var err_txt = tr("File failed to save. Error code %s (%s)"
						) % [err, error_string(err)]
					push_error(err_txt)
	else:
		var exporter = null
		if project.file_format == FileFormat.APNG:
			exporter = AImgIOAPNGExporter.new()
		else:
			exporter = GIFExporterInterface.new()
		var details := {
			"exporter": exporter,
			"export_paths": export_paths,
		}
		export_animated(details)
		
	return true


func export_animated(args: Dictionary):
	var exporter: AImgIOBaseExporter = args["exporter"]

	# Transform into AImgIO form
	var packed_frames := []
	for i in processed_images.size():
		packed_frames.append({
			'content': processed_images[i],
			'duration': durations[i]
		})

	# Export and save GIF/APNG
	var file_data = exporter.export(packed_frames, project.fps)

	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(
			file_data, args["export_paths"][0], exporter.mime_type)
	else:
		var file := FileAccess.open(args["export_paths"][0], FileAccess.WRITE)
		file.store_buffer(file_data)
		file.close()


func file_format_string(format_enum: int) -> String:
	match format_enum:
		# these are overrides
		# (if they are not given, they will generate themselves based on the enum key name)
		FileFormat.PNG:
			return "PNG Image"
		FileFormat.GIF:
			return "GIF Image"
		FileFormat.APNG:
			return "APNG Image"
		_:
			# If a file format description is not found, try generating one
			for key in FileFormat.keys():
				if FileFormat[key] == format_enum:
					return str(key.capitalize())
			return ""


func file_format_description(format_enum: int) -> String:
	match format_enum:
		# these are overrides
		# (if they are not given, they will generate themselves based on the enum key name)
		FileFormat.PNG:
			return "PNG Image"
		FileFormat.GIF:
			return "GIF Image"
		FileFormat.APNG:
			return "APNG Image"
		_:
			# If a file format description is not found, try generating one
			for key in FileFormat.keys():
				if FileFormat[key] == format_enum:
					return str(key.capitalize())
			return ""


func get_anim_tag_and_start_id(procd_id: int) -> Array:
	var result = null
	if not project:
		return result
	for anim_tag in project.animation_tags:
		# Check if processed image is in frame tag and 
		# assign frame tag and start id if yes Then stop
		if (procd_id + 1) >= anim_tag.from and (procd_id + 1) <= anim_tag.to:
			result = [anim_tag.name, anim_tag.from]
			break
	return result


func blend_layers(image: Image, frame: Frame, origin :Vector2i):
	if export_layer_type == ExportLayer.ALL_LAYERS:
		blend_all_layers(image, frame, origin)
	elif export_layer_type == ExportLayer.SELECTED_LAYERS:
		blend_selected_cels(image, frame, origin, project)


## Blends canvas layers into passed image starting from the origin position
func blend_all_layers(image: Image, frame: Frame, origin:Vector2i):
	
	var layer_i := 0
	for cel in frame.cels:
		if not project.layers[layer_i].is_visible_in_hierarchy():
			layer_i += 1
			continue
		if cel is GroupCel:
			layer_i += 1
			continue
		var cel_image := Image.new()
		cel_image.copy_from(cel.get_image())
		if cel.opacity < 1:  # If we have cel transparency
			for xx in cel_image.get_size().x:
				for yy in cel_image.get_size().y:
					var pixel_color = cel_image.get_pixel(xx, yy)
					var alpha :float = pixel_color.a * cel.opacity
					var color = Color(pixel_color.r, 
									  pixel_color.g, 
									  pixel_color.b, 
									  alpha)
					cel_image.set_pixel(xx, yy, color)
		image.blend_rect(cel_image, Rect2i(Vector2i.ZERO, project.size), origin)
		layer_i += 1


# Blends selected cels of the given frame into passed
# image starting from the origin position
func blend_selected_cels(image: Image, frame: Frame, 
						 origin:Vector2i, project:Project):
	for cel_ind in frame.cels.size():
		var test_array := [project.current_frame, cel_ind]
		if not test_array in project.selected_cels:
			continue
		if frame.cels[cel_ind] is GroupCel:
			continue
		if not project.layers[cel_ind].is_visible_in_hierarchy():
			continue
		var cel: BaseCel = frame.cels[cel_ind]
		var cel_image := Image.new()
		cel_image.copy_from(cel.get_image())
		if cel.opacity < 1:  # If we have cel transparency
			for xx in cel_image.get_size().x:
				for yy in cel_image.get_size().y:
					var pixel_color := cel_image.get_pixel(xx, yy)
					var alpha: float = pixel_color.a * cel.opacity
					cel_image.set_pixel(
						xx, yy, Color(pixel_color.r, pixel_color.g, pixel_color.b, alpha)
					)
		image.blend_rect(cel_image, Rect2i(Vector2i.ZERO, project.size), origin)


func frames_divided_by_spritesheet_lines() -> int:
	return ceili(number_of_frames / float(lines_count))
