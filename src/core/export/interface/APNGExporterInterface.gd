class_name APNGExporterInterface extends RefCounted

signal export_progressed

var total_frames := 0
var processed_frame := 0
var mime_type = "image/apng"

var aimgio_exporter = AImgIOAPNGExporter.new()

func export(packed_frames: Array,  fps:float=6) -> PackedByteArray:
	total_frames = packed_frames.size()
	var frames :Array[AImgIOFrame] = []
	for f in packed_frames:
		var frame = AImgIOFrame.new()
		frame.content = f.get('content', Image.new())
		frame.duration = f.get('duration', fps)
		frames.append(frame)
	return aimgio_exporter.export_animation(frames, fps, 
		self, "_increase_export_progress", null)


func _increase_export_progress(_args):
	processed_frame += 1
	export_progressed.emit(processed_frame/float(total_frames),
						   processed_frame, 
						   total_frames)
