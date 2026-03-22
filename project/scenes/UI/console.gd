@tool
class_name ConsoleUI extends GsomConsolePanel
static var singleton : ConsoleUI

func _ready():
	if not Engine.is_editor_hint():
		singleton = self
		GsomConsole.log("Hello World.")
	super._ready()
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():return
	if (Input.is_action_just_pressed("console_toggle")):
		visible = !visible
		GsomConsole.__is_visible = self.visible
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED)
		print("Opening console")
	#GsomConsole.handle_input(event)
