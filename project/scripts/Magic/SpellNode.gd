class_name SpellNode extends RigidBody3D
@export var has_gravity : bool :
	get: return gravity_scale > 0
	set(value):
		gravity_scale = 1 if value else 0
signal finished
