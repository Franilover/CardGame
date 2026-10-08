class_name MixerState
extends RefCounted

const SIZE: int = 9

var slots: Array[CardDefinition] = []

func _init() -> void:
	reset()

func reset() -> void:
	slots.clear()
	for index in range(SIZE):
		slots.append(null)

func is_valid_slot(index: int) -> bool:
	return index >= 0 and index < SIZE

func is_empty(index: int) -> bool:
	return is_valid_slot(index) and slots[index] == null

func get_ium(index: int) -> CardDefinition:
	if not is_valid_slot(index):
		return null
	return slots[index]

func place(index: int, card: CardDefinition) -> bool:
	if card == null or card.card_type != CardDefinition.CardType.IUM:
		return false
	if not is_empty(index):
		return false
	slots[index] = card
	return true

func remove(index: int) -> CardDefinition:
	if not is_valid_slot(index):
		return null
	var card: CardDefinition = slots[index]
	slots[index] = null
	return card

func get_iums() -> Array[CardDefinition]:
	var result: Array[CardDefinition] = []
	for card in slots:
		if card != null:
			result.append(card)
	return result

func count() -> int:
	return get_iums().size()
