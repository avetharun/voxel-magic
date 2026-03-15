extends RigidBody3D
class_name Pickup

@export var slot_data: SlotData
@onready var sprite_3d = $Sprite3D
const pickup = preload("uid://tnyppg70ee8u")
@onready var colliders: Array[CollisionShape3D] = [$CollisionShape3D, $Area3D/CollisionShape3D2]

func _ready()-> void:
	sprite_3d.texture = slot_data.item_data.texture
	

func _physics_process(delta):
	sprite_3d.rotate_y(delta)

func _on_area_3d_body_entered(body):
	if body == PlayerManager.player and body.inventory_data.pick_up_slot_data(slot_data):
		queue_free()
	if body is Pickup and body != self and body.slot_data.can_fully_merge_with(slot_data):
		if get_instance_id() < body.get_instance_id():
			create_merged_instance.call_deferred(slot_data, body)


func create_merged_instance(other_slot_data: SlotData, other_body):
	slot_data.fully_merge_with(other_slot_data)
	other_body.queue_free()
