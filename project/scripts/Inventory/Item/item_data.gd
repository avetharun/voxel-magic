extends Resource
class_name ItemData

@export var name: String = ""
@export_multiline var description: String = ""
@export var stackable: bool = false
@export var texture: AtlasTexture

func use(target) -> void:
	#this function exists so that no matter what child-scripts exist they have the ability to call the USE function
	pass
 
