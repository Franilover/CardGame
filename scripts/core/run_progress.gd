extends Node

const SAVE_PATH := "user://run_progress.json"
const EXPLORATION_COUNT := 5

var mode: String = "adventure"
var selected_character_style: String = "guardian"
var encounter_index: int = 0
var deck_ids: Array[String] = []
var unlocked_creature_ids: Array[String] = []
var selected_adventure_creature_id: String = ""

func _ready() -> void:
	_load_progress()

func start_mode(mode_name: String) -> void:
	if mode_name == "combat":
		mode = "combat"
		encounter_index = 0
	elif mode_name == "bosses":
		mode = "bosses"
		encounter_index = EXPLORATION_COUNT
	else:
		mode = "adventure"
		encounter_index = 0
	selected_adventure_creature_id = ""
	_save_progress()

func is_creature_unlocked(creature_id: String) -> bool:
	return unlocked_creature_ids.has(creature_id)

func unlock_creature_after_adventure_victory(creature_id: String, creature_name: String) -> bool:
	if mode != "adventure" or creature_id.is_empty() or unlocked_creature_ids.has(creature_id):
		return false
	unlocked_creature_ids.append(creature_id)
	_save_progress()
	return true

func is_boss_encounter() -> bool:
	return mode == "bosses" or (mode != "combat" and encounter_index >= EXPLORATION_COUNT)

func encounter_label() -> String:
	if is_boss_encounter():
		return "JEFE"
	return "EXPLORACIÓN %d/%d" % [encounter_index + 1, EXPLORATION_COUNT]

func ensure_deck(seed_cards: Array[CardDefinition], minimum_creatures: int = 3) -> void:
	var canonical_creatures: Array[CardDefinition] = []
	var canonical_objects: Array[CardDefinition] = []
	var seen: Dictionary = {}
	var valid_ids: Dictionary = {}
	for card in seed_cards:
		if card == null:
			continue
		valid_ids[card.id] = card
		if seen.has(card.id):
			continue
		seen[card.id] = true
		if card.card_type == CardDefinition.CardType.CREATURE:
			canonical_creatures.append(card)
		elif card.card_type == CardDefinition.CardType.OBJECT and canonical_objects.is_empty():
			canonical_objects.append(card)

	var filtered_ids: Array[String] = []
	for card_id in deck_ids:
		if valid_ids.has(card_id):
			filtered_ids.append(card_id)
	deck_ids = filtered_ids

	if deck_ids.is_empty():
		var starter_cards: Array[CardDefinition] = []
		for index in range(min(3, canonical_creatures.size())):
			starter_cards.append(canonical_creatures[index])
		starter_cards.append_array(canonical_objects)
		for card in starter_cards:
			for _copy_index in range(3):
				deck_ids.append(card.id)

	var creature_count := 0
	for card_id in deck_ids:
		var seed_card: CardDefinition = valid_ids.get(card_id) as CardDefinition
		if seed_card != null and seed_card.card_type == CardDefinition.CardType.CREATURE:
			creature_count += 1
	while creature_count < minimum_creatures and not canonical_creatures.is_empty():
		var next_creature: CardDefinition = canonical_creatures[creature_count % canonical_creatures.size()]
		deck_ids.append(next_creature.id)
		creature_count += 1

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
		deck_ids.clear()
		ensure_deck(fallback_cards)
		for card_id in deck_ids:
			var canonical_card: CardDefinition = catalog.get(card_id) as CardDefinition
			if canonical_card != null and (canonical_card.card_type == CardDefinition.CardType.CREATURE or canonical_card.card_type == CardDefinition.CardType.OBJECT or canonical_card.card_type == CardDefinition.CardType.CHARACTER):
				result.append(canonical_card.make_runtime_copy())
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
	var gained_names: Array[String] = []
	var lost_names: Array[String] = []
	for lost_card in state.lost_cards:
		if lost_card != null:
			_remove_one_id(lost_card.id)
			lost_names.append(lost_card.display_name)
	# Las cartas de criatura no se desbloquean en el modo táctico.
	# Solo la victoria en un encuentro individual de Aventura las añade a la colección.

	var reward_message := ""
	if not gained_names.is_empty():
		reward_message += " · Obtenidas: " + ", ".join(gained_names)
	if not lost_names.is_empty():
		reward_message += " · Perdidas: " + ", ".join(lost_names)
	if mode == "combat":
		if player_won:
			reward_message += " · Combate completado"
	else:
		if player_won and is_boss_encounter():
			var boss_reward := _find_reward_card(catalog_cards, CardDefinition.CardType.CREATURE, 0)
			if boss_reward != null:
				deck_ids.append(boss_reward.id)
				reward_message += " · Recompensa: " + boss_reward.display_name
			mode = "exploration"
			encounter_index = 0
		elif player_won:
			var object_reward := _find_reward_card(catalog_cards, CardDefinition.CardType.OBJECT, encounter_index)
			if object_reward != null:
				deck_ids.append(object_reward.id)
				reward_message += " · Objeto añadido: " + object_reward.display_name
			encounter_index += 1
		elif not player_won:
			mode = "adventure"
			encounter_index = 0
	_save_progress()
	return reward_message

func _find_reward_card(cards: Array[CardDefinition], desired_type: int, offset: int) -> CardDefinition:
	var options: Array[CardDefinition] = []
	for card in cards:
		if card != null and card.card_type == desired_type:
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
		"deck_ids": deck_ids,
		"unlocked_creature_ids": unlocked_creature_ids
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
	var saved_mode := str(parsed.get("mode", "adventure"))
	mode = saved_mode if saved_mode in ["adventure", "combat", "bosses"] else "adventure"
	encounter_index = clampi(int(parsed.get("encounter_index", 0)), 0, EXPLORATION_COUNT)
	deck_ids.clear()
	var saved_ids: Variant = parsed.get("deck_ids", [])
	if saved_ids is Array:
		for card_id in saved_ids:
			deck_ids.append(str(card_id))
	unlocked_creature_ids.clear()
	var saved_unlocked: Variant = parsed.get("unlocked_creature_ids", [])
	if saved_unlocked is Array:
		for creature_id in saved_unlocked:
			var id_string := str(creature_id)
			if not id_string.is_empty() and not unlocked_creature_ids.has(id_string):
				unlocked_creature_ids.append(id_string)
