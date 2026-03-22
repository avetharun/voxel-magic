extends CanvasLayer

class_name HUD

#player character reference variable
@onready var play_char : PlayerCharacter = $".."

#label references variables
@onready var frames_per_second_label_text: Label = %FramesPerSecondLabelText
func _process(_delta : float) -> void:
	display_current_FPS()
	
	display_properties()
	
func display_properties() -> void:
	#player character properties
	pass
func display_current_FPS() -> void:
	frames_per_second_label_text.set_text(str(Engine.get_frames_per_second()))
	
func round_to_3_decimals(value: float) -> float:
	return round(value * 1000.0) / 1000.0
	
	
	
	
	
