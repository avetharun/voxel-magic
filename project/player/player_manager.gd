extends Node

var player : PlayerCharacter
func _ready() -> void:
	GsomConsole.part_submitted_handlers.push_back(func(cmd_name : String, args : PackedStringArray):
		print(cmd_name)
	)
	for action in InputMap.get_actions():
		if not action.begins_with("ui_"):
			GsomConsole.register_action(action)
			#GsomConsole.log("Adding action " + action)
func use_slot_data(slot_data: SlotData)-> void:
	slot_data.item_data.use(player)
	
