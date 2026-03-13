class_name Player extends CharacterBody3D

static var singleton : Player
func _init():
	singleton = self
@export var camera : Camera3D
@export var head : Node3D
var camera_goal : Vector2 = Vector2.ZERO
@export var camera_smoothing : float = 0.999
@export var camera_sensitivity : float = 0.2
func _process(delta: float) -> void:
	head.rotation_degrees.y += camera_goal.x * camera_sensitivity
	camera.rotation_degrees.x += camera_goal.y * camera_sensitivity
	if camera_smoothing <= 0:
		camera_goal = Vector2.ZERO
	else:
		camera_goal *= delta * camera_smoothing
	if Input.is_action_just_pressed("escape_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	camera.rotation_degrees = camera.rotation_degrees.clamp(Vector3(-89, 0, 0), Vector3(89, 0, 0))
	head.rotation_degrees.y = wrapf(head.rotation_degrees.y, 0, 360)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion:
		camera_goal = -event.screen_relative
