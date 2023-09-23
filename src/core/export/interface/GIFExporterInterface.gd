class_name GIFExporterInterface

extends RefCounted


signal export_progressed

# Gif exporter
const GIFExporter := preload("res://addons/gdgifexporter/exporter.gd")
const MedianCutQuantization := preload(
	"res://addons/gdgifexporter/quantization/median_cut.gd")

var total_frames := 0
var processed_frame := 0
var mime_type = "image/gif"


func export(frames: Array, fps:float=6) -> PackedByteArray:
	var first_frame = frames[0]
	var first_img = first_frame.content
	var exporter := GIFExporter.new(first_img.get_width(), first_img.get_height())
	for frame in frames:
		var duration = frame.get('duration', fps)
		var content = frame.get('content', Image.new())
		exporter.add_frame(content, duration, MedianCutQuantization)
		_increase_export_progress()
	return exporter.export_file_data()


func _increase_export_progress():
	processed_frame += 1
	export_progressed.emit(processed_frame/float(total_frames),
						   processed_frame, 
						   total_frames)
						
