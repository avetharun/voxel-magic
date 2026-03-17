extends RigidBody3D
class_name Pickup

signal merge_requested(a: Node, b: Node)
var merge_locked := false
@export var slot_data: SlotData
@onready var sprite_3d = $Sprite3D
var id:=0 #main script assigns this
func _ready()-> void:
	sprite_3d.texture = slot_data.item_data.texture
	get_tree().call_group("main", "register_pickup", self)

func _physics_process(delta):
	sprite_3d.rotate_y(delta)

func _on_area_3d_body_entered(body):
	if body == PlayerManager.player and body.inventory_data.pick_up_slot_data(slot_data):
		queue_free()
		return
	
	if body is Pickup and body != self:
		if merge_locked or body.merge_locked:
			return
	
		# Lock both immediately
		merge_locked = true
		body.merge_locked = true

		emit_signal("merge_requested", self, body)
