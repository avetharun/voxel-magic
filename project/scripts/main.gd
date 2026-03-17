extends Node3D
@onready var player = $PlayerCharacter
@onready var inventory_interface = $UI/InventoryInterface
@onready var hot_bar_inventory = $UI/HotBarInventory

const Pickup = preload("uid://tnyppg70ee8u")


func _ready()-> void:
	player.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	hot_bar_inventory.set_inventory_data(player.inventory_data)
	
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)
		pass

func toggle_inventory_interface(external_inventory_owner = null) -> void:
	inventory_interface.visible = !inventory_interface.visible
	
	if inventory_interface.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hot_bar_inventory.hide()
	else:
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hot_bar_inventory.show()
	
	if external_inventory_owner and inventory_interface.is_visible():
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()
	


func _on_inventory_interface_drop_slot_data(slot_data):
	var pick_up = Pickup.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = player.get_drop_position()
	add_child(pick_up)

var next_pickup_id := 1

func generate_pickup_id() -> int:
	var id = next_pickup_id
	next_pickup_id += 1
	return id

func register_pickup(pickup: Pickup):
	pickup.id = generate_pickup_id()
	pickup.merge_requested.connect(_on_merge_requested)

func _on_merge_requested(a: Pickup, b: Pickup):
	if !is_instance_valid(a) or !is_instance_valid(b):
		return

	if !a.slot_data.can_fully_merge_with(b.slot_data):
		return

	perform_merge(a, b)

func perform_merge(a, b):
	var survivor = a
	var consumed = b

	if b.id < a.id:
		survivor = b
		consumed = a

	survivor.slot_data.fully_merge_with(consumed.slot_data)
	consumed.queue_free()

	# Unlock the survivor so it can merge again later
	survivor.merge_locked = false
