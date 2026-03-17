extends Resource
class_name SpellComponent

@export var name: String = ""
@export_multiline var description: String = ""
enum ComponentType {
	ATTRIBUTES, ELEMENT, EXECUTE, NO_OP
}
@export var component_type : ComponentType = ComponentType.NO_OP

@export var texture: AtlasTexture
