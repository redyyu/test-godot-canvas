class_name Group
## A class for group layer properties

extends RefCounted


var name :String = 'Group'
var layers :Array[BaseLayer] = []


func set_to_default(number: int):
	name = tr("Group") + " %s" % number


func add_layer(layer:BaseLayer):
	layers.append(layer)
	

func remove_layer(layer:BaseLayer):
	if layers.has(layer):
		layers.erase(layer)
