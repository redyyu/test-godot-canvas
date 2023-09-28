class_name Frame extends RefCounted
# A class for frame properties.
# A frame is a collection of cels, for each layer.

var cels: Array[BaseCel]
var duration := 1.0


func append_cel(cel :BaseCel):
	cels.append(cel)
	

func erase_cel(cel :BaseCel):
	if cels.has(cel):
		cels.erase(cel)
