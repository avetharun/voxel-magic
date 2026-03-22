# Generic runtime entity/node filtering
class_name MagicSpell extends Resource
func _init(_name:String, _components:Array[SpellComponent], _predicate:TriggerPredicate = TriggerPredicate._FilterAlwaysTrue) -> void:
	self.name = _name
	self.predicate = _predicate
	self.components = _components
var name : String
var predicate : TriggerPredicate
var next : MagicSpell
var components : Array[SpellComponent] = []
func add_component(component:SpellComponent)->void:
	components.push_back(component)
func run(position:Vector3):
	var spell_node : SpellNode = SpellNode.new()
	if (predicate.is_valid(PlayerManager.player)):
		for component:SpellComponent in components:
			component.execute(spell_node)
	else:
		# Fizzle spell
		spell_node=(load("uid://gbhes2avc1m5") as PackedScene).instantiate() as SpellNode
	PlayerManager.player.get_tree().root.add_child(spell_node)
