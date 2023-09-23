extends RefCounted

class_name BaseLayer
# Base class for layer properties. Different layer types extend from this class.

enum LayerTypes {
	GROUP,
	PIXEL,
}

var name := ""
var index : = 0
var opacity := 1.0
var parent :BaseLayer
var expanded :bool = false
var visible :bool = true
var locked :bool = false
var cels_linked :bool = false
var cel_link_sets :Array[Dictionary] = []  
# Each Dictionary represents a cel's "link set"z


func is_ancestor_of(layer: BaseLayer):
	# Returns true if this is a direct or indirect parent of layer
	if layer.parent == self:
		return true
	elif is_instance_valid(layer.parent):
		return is_ancestor_of(layer.parent)
	return false


func is_expanded_in_hierarchy() -> bool:
	if is_instance_valid(parent):
		return parent.expanded and parent.is_expanded_in_hierarchy()
	return true


func is_visible_in_hierarchy() -> bool:
	if is_instance_valid(parent) and visible:
		return parent.is_visible_in_hierarchy()
	return visible


func is_locked_in_hierarchy() -> bool:
	if is_instance_valid(parent) and not locked:
		return parent.is_locked_in_hierarchy()
	return locked


func get_hierarchy_depth() -> int:
	if is_instance_valid(parent):
		return parent.get_hierarchy_depth() + 1
	return 0


func get_layer_path() -> String:
	if is_instance_valid(parent):
		return str(parent.get_layer_path(), "/", name)
	return name


## Links a cel to link_set if its a Dictionary, or unlinks if null.
## Content/image_texture are handled separately for undo related reasons
func link_cel(cel: BaseCel, link_set = null):
	# Erase from the cel's current link_set
	if cel.link_set is Dictionary:
		if cel.link_set.has("cels"):
			cel.link_set["cels"].erase(cel)
			if cel.link_set["cels"].is_empty():
				cel_link_sets.erase(cel.link_set)
		else:
			cel_link_sets.erase(cel.link_set)

	# Add to link_set
	cel.link_set = link_set
	if link_set is Dictionary:
		if not link_set.has("cels"):
			link_set["cels"] = []
		link_set["cels"].append(cel)
		if not cel_link_sets.has(link_set):
			if not link_set.has("hue"):
				var hues = PackedFloat32Array()
				for other_link_set in cel_link_sets:
					hues.append(other_link_set["hue"])
				if hues.is_empty():
					link_set["hue"] = Color.GREEN.h
				else:  # Calculate the largest gap in hue between existing link sets:
					hues.sort()
					# Start gap between the highest and lowest hues, otherwise its hard to include
					var largest_gap_pos = hues[-1]
					var largest_gap_size = 1.0 - (hues[-1] - hues[0])
					for h in hues.size() - 1:
						var gap_size: float = hues[h + 1] - hues[h]
						if gap_size > largest_gap_size:
							largest_gap_pos = hues[h]
							largest_gap_size = gap_size
					link_set["hue"] = wrapf(largest_gap_pos + largest_gap_size / 2.0, 0, 1)
			cel_link_sets.append(link_set)


# Methods to Override:

func set_name_to_default(number: int) -> void:
	name = tr("Layer") + " %s" % number


func can_layer_get_drawn() -> bool:
	return false

