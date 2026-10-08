extends Node

const SAVE_PATH := "user://run_progress.json"
const EXPLORATION_COUNT := 5

var mode: String = "exploration"
var encounter_index: int = 0
var deck_ids: Array[String] = []

func _ready() -> void:
	_load_progress()

func start_mode(mode_name: String) -> void:
	mode = "bosses" if mode_name == "bosses" else "exploration"
	encounter_index = EXPLORATION_COUNT if mode == "bosses" else 0
	_save_progress()

func is_boss_encounter() -> bool:
	return mode == "bosses" or encounter_index >= EXPLORATION_COUNT

func encounter_label() -> String:
	if is_boss_encounter():
		return "JEFE"
	return "EXPLORACIÓN %d/%d" % [encounter_index + 1, EXPLORATION_COUNT]

func ensure_deck(seed_cards: Array[CardDefinition]) -> void:
	if not deck_ids.is_empty():
		return
	var creatures: Array[CardDefinition] = []
	var objects: Array[CardDefinition] = []
	var seen: Dictionary = {}
	for card in seed_cards:
		if card == null or seen.has(card.id):
			continue
		seen[card.id] = true
		if card.card_type == CardDefinition.CardType.CREATURE and creatures.size() < 3:
			creatures.append(card)
		elif card.card_type == CardDefinition.CardType.OBJECT and objects.is_empty():
			objects.append(card)
	for card in creatures + objects:
		for copy_index in range(3):
			deck_ids.append(card.id)
	if deck_ids.is_empty():
		for card in seed_cards:
			if card != null:
				deck_ids.append(card.id)
				if deck_ids.size() >= 12:
					break
	_save_progress()

func build_player_deck(catalog_cards: Array[CardDefinition], fallback_cards: Array[CardDefinition]) -> Array[CardDefinition]:
	var catalog: Dictionary = {}
	for card in catalog_cards:
		if card != null and not catalog.has(card.id):
			catalog[card.id] = card
	for card in fallback_cards:
		if card != null and not catalog.has(card.id):
			catalog[card.id] = card
	var result: Array[CardDefinition] = []
	for card_id in deck_ids:
		var card: CardDefinition = catalog.get(card_id) as CardDefinition
		if card != null and (card.card_type == CardDefinition.CardType.CREATURE or card.card_type == CardDefinition.CardType.OBJECT or card.card_type == CardDefinition.CardType.CHARACTER):
			result.append(card.make_runtime_copy())
	if result.is_empty():
		ensure_deck(fallback_cards)
		for card_id in deck_ids:
			var fallback: CardDefinition = catalog.get(card_id) as CardDefinition
			if fallback != null:
				result.append(fallback.make_runtime_copy())
	return result

func build_enemy_deck(base_deck: Array[CardDefinition]) -> Array[CardDefinition]:
	var result: Array[CardDefinition] = []
	for source in base_deck:
		if source == null:
			continue
		var card: CardDefinition = source.make_runtime_copy()
		if is_boss_encounter():
			card.attack += 2
			card.health += 3
			card.cost = max(0, card.cost)
			card.display_name = "Jefe · " + card.display_name
		result.append(card)
	return result

func finish_battle(state: BattleState, player_won: bool, catalog_cards: Array[CardDefinition]) -> String:
	for lost_card in state.lost_cards:
		if lost_card != null:
			_remove_one_id(lost_card.id)
	for gained_card in state.unlocked_cards:
		if gained_card != null:
			deck_ids.append(gained_card.id)

	var reward_message := ""
	if player_won:
		if is_boss_encounter():
			var boss_reward := _find_reward_card(catalog_cards, CardDefinition.CardType.CREATURE, 0)
			if boss_reward != null:
				deck_ids.append(boss_reward.id)
				reward_message = " · Recompensa: " + boss_reward.display_name
			mode = "exploration"
			encounter_index = 0
		else:
			var object_reward := _find_reward_card(catalog_cards, CardDefinition.CardType.OBJECT, encounter_index)
			if object_reward != null:
				deck_ids.append(object_reward.id)
				reward_message = " · Objeto añadido: " + object_reward.display_name
			encounter_index += 1
	else:
		mode = "exploration"
		encounter_index = 0
	_save_progress()
	return reward_message

func _find_reward_card(cards: Array[CardDefinition], desired_type: CardDefinition.CardType, offset: int) -> CardDefinition:
	var options: Array[CardDefinition] = []
	for card in cards:
		if card != null and card.card_type == desired_type:
			var already_added := false
			for current_id in deck_ids:
				if current_id == card.id:
					already_added = true
					break
			if not already_added:
				options.append(card)
	if options.is_empty():
		for card in CardCatalog.starter_deck():
			if card.card_type == desired_type:
				options.append(card)
	if options.is_empty():
		return null
	return options[posmod(offset, options.size())]

func _remove_one_id(card_id: String) -> void:
	for index in range(deck_ids.size()):
		if deck_ids[index] == card_id:
			deck_ids.remove_at(index)
			return

func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar el progreso local.")
		return
	file.store_string(JSON.stringify({
		"mode": mode,
		"encounter_index": encounter_index,
		"deck_ids": deck_ids
	}))

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	mode = "bosses" if str(parsed.get("mode", "exploration")) == "bosses" else "exploration"
	encounter_index = clampi(int(parsed.get("encounter_index", 0)), 0, EXPLORATION_COUNT)
	deck_ids.clear()
	var saved_ids: Variant = parsed.get("deck_ids", [])
	if saved_ids is Array:
		for card_id in saved_ids:
			deck_ids.append(str(card_id))
