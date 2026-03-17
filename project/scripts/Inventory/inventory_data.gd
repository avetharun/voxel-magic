extends Resource
class_name InventoryData

signal inventory_updated(inventory_data: InventoryData)
signal inventory_interact(inventory_data: InventoryData, index: int, button:int)

@export var slot_datas: Array[SlotData]

func grab_slot_data(index:int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if slot_data:
		slot_datas[index] = null
		inventory_updated.emit(self)
		return slot_data
	else:
		return null

func grab_half_slot_data(index:int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if slot_data and slot_data.quantity >1:
		var return_slot_data = slot_data.duplicate()
		slot_data.quantity = slot_data.quantity/2
		return_slot_data.quantity -= slot_data.quantity
		inventory_updated.emit(self)
		return return_slot_data
	else:
		return null


func drop_slot_data(grabbed_slot_data: SlotData, index:int) -> SlotData:
	var slot_data = slot_datas[index]
	
	var return_slot_data:SlotData
	
	if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data)
	elif slot_data and slot_data.can_overflow(grabbed_slot_data) and slot_data.quantity < slot_data.MAX_STACK_SIZE:
		return_slot_data = slot_data.overflow_with(grabbed_slot_data)
	else:
		slot_datas[index] = grabbed_slot_data
		return_slot_data = slot_data
	
	inventory_updated.emit(self)
	return return_slot_data

func drop_single_slot_data(grabbed_slot_data: SlotData, index:int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if not slot_data:
		slot_datas[index] = grabbed_slot_data.create_single_slot_data()
	elif slot_data.can_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data.create_single_slot_data())
		
	inventory_updated.emit(self)
	
	if grabbed_slot_data.quantity >0:
		return grabbed_slot_data
	else:
		return null

func use_slot_data(index: int)-> void:
	var slot_data = slot_datas[index]
	
	if not slot_data:
		return
	if slot_data.item_data is ItemDataConsumable:
		slot_data.quantity -=1
		if slot_data.quantity <1:
			slot_datas[index] = null
			
	
	print(slot_data.item_data.name)
	PlayerManager.use_slot_data(slot_data)
	inventory_updated.emit(self)

func pick_up_slot_data(slot_data: SlotData)-> bool:
	
	for index in slot_datas.size():
		if slot_datas[index] and slot_datas[index].can_fully_merge_with(slot_data):
			slot_datas[index].fully_merge_with(slot_data)
			inventory_updated.emit(self)
			return true
	
	for index in slot_datas.size():
		if slot_datas[index] and slot_datas[index].can_overflow(slot_data):
			slot_datas[index].overflow_with(slot_data)
			if not slot_datas[index+1]:
				slot_datas[index+1] = slot_data
			else:
				continue
			inventory_updated.emit(self)
			return true
	
	for index in slot_datas.size():
		if not slot_datas[index]:
			slot_datas[index] = slot_data
			inventory_updated.emit(self)
			return true
	return false

func on_slot_shift_clicked(other_inventory:InventoryData, slot_data:SlotData, source_index:int):
	if other_inventory:
		for index in other_inventory.slot_datas.size():
			if not other_inventory.slot_datas[index] or other_inventory.slot_datas[index].can_fully_merge_with(slot_data):
				other_inventory.slot_datas[index].fully_merge_with(slot_data)
				slot_datas[source_index] = null
				inventory_updated.emit(self)
				other_inventory.inventory_updated.emit(other_inventory)
				return true
	else:
		var start_index = 24-6
		var end_index = 24
		if source_index >= start_index: start_index = 0
		for index in range(start_index, end_index):
			var can_overflow = slot_datas[index].can_overflow(slot_data) if slot_datas[index] else false
			if not slot_datas[index] or slot_datas[index].can_fully_merge_with(slot_data) or can_overflow:
				if slot_datas[index]:
					if can_overflow:
						print("slot can overflow, value is greater than max_value, next slot is never checked")
						slot_data = slot_datas[index].overflow_with(slot_data)
						slot_datas[source_index] = null
						continue
					else:
						slot_datas[index].fully_merge_with(slot_data)
						slot_datas[source_index] = null
				else:
					slot_datas[index] = slot_data
					slot_datas[source_index] = null
				inventory_updated.emit(self)
				return true


func on_slot_clicked(index: int, button:int)->void:
	inventory_interact.emit(self, index, button)
