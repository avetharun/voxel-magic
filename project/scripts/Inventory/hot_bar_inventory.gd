extends PanelContainer

signal hot_bar_use(index:int)

const Slot = preload("uid://cd8bpqekm44d1")

@onready var h_box_container = $MarginContainer/HBoxContainer

func _unhandled_key_input(event):
	if not visible or not event.is_pressed():
		return
	
	if range(KEY_1, KEY_7).has(event.keycode):
		hot_bar_use.emit((event.keycode - KEY_1)+24-6)
		print("attempted to use slot index ",event.keycode- KEY_1)
	

func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)

func populate_hot_bar(inventory_data: InventoryData) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
	
	for slot_data in inventory_data.slot_datas.slice(24-6,24):
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		
		if slot_data != null:
			slot.set_slot_data(slot_data)
			pass
