class_name BattleState
extends RefCounted

signal state_changed
signal event_occurred(message: String)
signal battle_finished(player_won: bool)

const BOARD_ROWS: int = BattleBoard.ROWS
const BOARD_COLUMNS: int = BattleBoard.COLUMNS
const BOARD_CELLS: int = BattleBoard.CELL_COUNT
const MAX_HAND: int = 8
const START_HAND: int = 5
const ACTIONS_PER_TURN: int = 3
const MAX_ETHERIUM: int = 10
const HERO_MAX_HEALTH: int = 30
const MOVE_ETHERIUM_COST: int = 1

const PLAYER_SLOTS: int = BOARD_CELLS
const ENEMY_SLOTS: int = BOARD_CELLS
const GRID_COLUMNS: int = BOARD_COLUMNS

var turn: int = 1
var player_actions: int = ACTIONS_PER_TURN
var player_etherium: int = 3
var player_max_etherium: int = 3
var enemy_etherium: int = 3
var enemy_max_etherium: int = 3
var player_health: int = HERO_MAX_HEALTH
var enemy_health: int = HERO_MAX_HEALTH

var player_hero: CardDefinition
var enemy_hero: CardDefinition
var player_hero_slot: int = BattleBoard.PLAYER_HERO_SLOT
var enemy_hero_slot: int = BattleBoard.ENEMY_HERO_SLOT

var board: BattleBoard = BattleBoard.new()
var mixer: MixerState = MixerState.new()
var process_catalog: Array[CardDefinition] = []

var hand: Array[CardDefinition] = []
var deck: Array[CardDefinition] = []
var discard: Array[CardDefinition] = []
var enemy_deck: Array[CardDefinition] = []
var enemy_discard: Array[CardDefinition] = []

var finished: bool = false
var winner_is_player: bool = false
var fatigue_damage: int = 1

func reset() -> void:
	turn = 1
	player_actions = ACTIONS_PER_TURN
	player_etherium = 3
	player_max_etherium = 3
	enemy_etherium = 3
	enemy_max_etherium = 3
	player_health = HERO_MAX_HEALTH
	enemy_health = HERO_MAX_HEALTH
	finished = false
	winner_is_player = false
	fatigue_damage = 1
	board.reset()
	mixer.reset()
	player_hero = _create_hero("Rey de Garlia")
	enemy_hero = _create_hero("Reina de Garlia")
	board.place_hero(player_hero_slot, player_hero, BattleBoard.Owner.PLAYER)
	board.place_hero(enemy_hero_slot, enemy_hero, BattleBoard.Owner.ENEMY)
	_sync_health_mirrors()
	process_catalog.clear()
	hand.clear()
	deck.clear()
	discard.clear()
	enemy_deck.clear()
	enemy_discard.clear()
	state_changed.emit()

func setup(
	player_cards: Array[CardDefinition],
	enemy_cards: Array[CardDefinition],
	canonical_processes: Array[CardDefinition] = []
) -> void:
	reset()
	deck = _runtime_copies(player_cards)
	enemy_deck = _runtime_copies(enemy_cards)
	process_catalog = _runtime_copies(canonical_processes)
	deck.shuffle()
	enemy_deck.shuffle()
	for index in range(START_HAND):
		draw_card()
	state_changed.emit()

func _runtime_copies(cards: Array[CardDefinition]) -> Array[CardDefinition]:
	var result: Array[CardDefinition] = []
	for card in cards:
		if card != null:
			result.append(card.make_runtime_copy())
	return result

func draw_card() -> CardDefinition:
	if hand.size() >= MAX_HAND:
		return null
	if deck.is_empty():
		_damage_unit(player_hero, fatigue_damage)
		fatigue_damage += 1
		_check_finished()
		event_occurred.emit("fatiga")
		state_changed.emit()
		return null

	var card: CardDefinition = deck.pop_front()
	hand.append(card)
	state_changed.emit()
	return card

func can_play(card: CardDefinition) -> bool:
	return not finished and card != null and hand.has(card) and card.cost <= player_etherium and player_actions > 0

func play_card(card: CardDefinition, slot: int = -1, target_enemy: bool = false) -> bool:
	if not can_play(card):
		return false

	if card.is_unit():
		if not board.place(slot, card, BattleBoard.Owner.PLAYER):
			return false
		card.exhausted = true
		_event("Entró %s." % card.display_name)
	else:
		if not _resolve_non_unit(card, slot, target_enemy):
			return false

	player_etherium -= card.cost
	player_actions -= 1
	hand.erase(card)
	_check_finished()
	state_changed.emit()
	return true

func _resolve_non_unit(card: CardDefinition, target_slot: int, target_enemy: bool) -> bool:
	match card.effect_kind:
		"buff":
			if target_enemy:
				return false
			var unit: CardDefinition = board.get_card(target_slot)
			if board.get_owner(target_slot) != BattleBoard.Owner.PLAYER or unit == null:
				return false
			unit.attack += card.effect_value
			unit.health += card.effect_secondary
			_event("%s recibió un refuerzo." % unit.display_name)
			return true
		"draw":
			draw_card()
			_event("%s alteró el flujo de cartas." % card.display_name)
			return true
		"damage":
			if not target_enemy:
				return false
			var enemy_unit: CardDefinition = board.get_card(target_slot)
			if board.get_owner(target_slot) != BattleBoard.Owner.ENEMY or enemy_unit == null:
				return false
			_damage_unit(enemy_unit, card.effect_value)
			_event("%s hizo %d de daño." % [card.display_name, card.effect_value])
			_cleanup_boards()
			return true
		"damage_all":
			for index in board.indices_for_owner(BattleBoard.Owner.ENEMY):
				if index != enemy_hero_slot:
					_damage_unit(board.get_card(index), card.effect_value)
			_damage_unit(enemy_hero, card.effect_secondary)
			_event("%s afectó todo el campo enemigo." % card.display_name)
			_cleanup_boards()
			return true
	return false

func move_unit(player_slot: int, target_slot: int) -> bool:
	if finished or player_etherium < MOVE_ETHERIUM_COST:
		return false
	var unit: CardDefinition = board.get_card(player_slot)
	if board.get_owner(player_slot) != BattleBoard.Owner.PLAYER or unit == null:
		return false
	if not unit.is_unit() or unit.exhausted:
		return false
	if not board.move(player_slot, target_slot, BattleBoard.Owner.PLAYER, unit.movement):
		return false
	player_etherium -= MOVE_ETHERIUM_COST
	_event("%s se movió por %d Eterium." % [unit.display_name, MOVE_ETHERIUM_COST])
	state_changed.emit()
	return true

func attack_unit(player_slot: int, enemy_slot: int = -1) -> bool:
	if finished or player_actions <= 0:
		return false
	var attacker: CardDefinition = board.get_card(player_slot)
	if board.get_owner(player_slot) != BattleBoard.Owner.PLAYER or attacker == null or not attacker.can_attack():
		return false
	if enemy_slot < 0 or enemy_slot >= BattleBoard.CELL_COUNT:
		return false

	var defender: CardDefinition = board.get_card(enemy_slot)
	if board.get_owner(enemy_slot) != BattleBoard.Owner.ENEMY or defender == null:
		return false
	if board.distance(player_slot, enemy_slot) > max(1, attacker.attack_range):
		return false

	attacker.has_attacked = true
	attacker.has_acted = true
	player_actions -= 1
	_damage_unit(defender, attacker.attack)
	if defender.health > 0 and defender.counter_attack and board.distance(player_slot, enemy_slot) <= max(1, defender.attack_range):
		_damage_unit(attacker, defender.attack)
	_event("%s atacó a %s." % [attacker.display_name, defender.display_name])

	_cleanup_boards()
	_check_finished()
	state_changed.emit()
	return true

func place_ium_in_mixer(hand_index: int, mixer_slot: int) -> bool:
	if finished or hand_index < 0 or hand_index >= hand.size():
		return false
	var card: CardDefinition = hand[hand_index]
	if card == null or card.card_type != CardDefinition.CardType.IUM:
		return false
	if not mixer.place(mixer_slot, card):
		return false
	hand.remove_at(hand_index)
	_event("%s entró al mezclador." % card.display_name)
	state_changed.emit()
	return true

func remove_ium_from_mixer(mixer_slot: int) -> bool:
	if finished or hand.size() >= MAX_HAND:
		return false
	var card: CardDefinition = mixer.remove(mixer_slot)
	if card == null:
		return false
	hand.append(card)
	_event("%s regresó al inventario." % card.display_name)
	state_changed.emit()
	return true

func resolve_mixer() -> BattleResult:
	if finished:
		return BattleResult.error("BATTLE_FINISHED", "La batalla ya terminó.")
	if player_actions <= 0:
		return BattleResult.error("NO_ACTIONS", "No quedan acciones.")
	if player_etherium <= 0:
		return BattleResult.error("NO_ETHERIUM", "No tienes Eterium suficiente.")
	if mixer.count() < 2:
		return BattleResult.error("MIXER_NEEDS_INPUTS", "Se necesitan al menos dos IUMs.")
	if hand.size() >= MAX_HAND:
		return BattleResult.error("HAND_FULL", "La mano está llena.")

	var process: CardDefinition = MixerEngine.find_process(mixer, process_catalog)
	if process == null:
		return BattleResult.error("NO_CANONICAL_RECIPE", "No existe una receta canónica para esta combinación.")

	for card in mixer.get_iums():
		discard.append(card)

	mixer.reset()
	hand.append(process.make_runtime_copy())
	player_etherium -= 1
	player_actions -= 1
	_event("El mezclador generó %s." % process.display_name)
	state_changed.emit()
	return BattleResult.ok("Proceso generado: %s." % process.display_name)

func _damage_unit(unit: CardDefinition, amount: int) -> void:
	if unit == null:
		return
	var remaining: int = max(0, amount)
	if unit.armor > 0:
		var absorbed: int = min(unit.armor, remaining)
		unit.armor -= absorbed
		remaining -= absorbed
	unit.health -= remaining
	_sync_health_mirrors()

func _sync_health_mirrors() -> void:
	player_health = player_hero.health if player_hero != null else HERO_MAX_HEALTH
	enemy_health = enemy_hero.health if enemy_hero != null else HERO_MAX_HEALTH

func _create_hero(name: String) -> CardDefinition:
	var hero := CardDefinition.new()
	hero.id = name.to_lower().replace(" ", "_")
	hero.canonical_id = hero.id
	hero.canonical_table = "personajes_game"
	hero.display_name = name
	hero.card_type = CardDefinition.CardType.CHARACTER
	hero.health = HERO_MAX_HEALTH
	hero.cost = 0
	hero.attack = 0
	hero.movement = 1
	hero.attack_range = 0
	hero.counter_attack = false
	hero.canonical_source = "local"
	hero.tags = ["personaje", "heroe"]
	return hero

func _cleanup_boards() -> void:
	for index in board.indices_for_owner(BattleBoard.Owner.PLAYER):
		var player_unit: CardDefinition = board.get_card(index)
		if index != player_hero_slot and player_unit != null and not player_unit.alive():
			discard.append(board.remove(index))
	for index in board.indices_for_owner(BattleBoard.Owner.ENEMY):
		var enemy_unit: CardDefinition = board.get_card(index)
		if index != enemy_hero_slot and enemy_unit != null and not enemy_unit.alive():
			enemy_discard.append(board.remove(index))

func _reset_units_for_owner(owner: int) -> void:
	for index in board.indices_for_owner(owner):
		var unit: CardDefinition = board.get_card(index)
		if unit != null:
			unit.exhausted = false
			unit.has_attacked = false
			unit.has_acted = false

func end_turn() -> void:
	if finished:
		return
	_enemy_turn()
	if finished:
		return
	turn += 1
	_reset_units_for_owner(BattleBoard.Owner.PLAYER)
	player_max_etherium = min(MAX_ETHERIUM, player_max_etherium + 1)
	player_etherium = player_max_etherium
	player_actions = ACTIONS_PER_TURN
	draw_card()
	_cleanup_boards()
	state_changed.emit()

func _enemy_turn() -> void:
	_reset_units_for_owner(BattleBoard.Owner.ENEMY)
	enemy_max_etherium = min(MAX_ETHERIUM, enemy_max_etherium + 1)
	enemy_etherium = enemy_max_etherium

	var actions: int = ACTIONS_PER_TURN
	while actions > 0:
		var best_card: CardDefinition = null
		var best_index: int = -1

		for index in range(enemy_deck.size()):
			var candidate: CardDefinition = enemy_deck[index]
			if candidate == null or candidate.cost > enemy_etherium:
				continue
			if candidate.is_unit() and board.first_empty_in_zone(BattleBoard.Owner.ENEMY) < 0:
				continue
			if best_card == null or candidate.cost < best_card.cost:
				best_card = candidate
				best_index = index

		if best_card == null:
			break

		var played: bool = false
		if best_card.is_unit():
			var slot := board.first_empty_in_zone(BattleBoard.Owner.ENEMY)
			if slot >= 0:
				var enemy_card: CardDefinition = enemy_deck.pop_at(best_index)
				if board.place(slot, enemy_card, BattleBoard.Owner.ENEMY):
					enemy_card.exhausted = true
					enemy_etherium -= enemy_card.cost
					actions -= 1
					played = true
					_event("El enemigo jugó %s." % enemy_card.display_name)
		else:
			var enemy_card: CardDefinition = enemy_deck.pop_at(best_index)
			if _resolve_enemy_non_unit(enemy_card):
				enemy_etherium -= enemy_card.cost
				actions -= 1
				played = true
				enemy_discard.append(enemy_card)

		if not played:
			break

	_enemy_move_units()

	for index in board.indices_for_owner(BattleBoard.Owner.ENEMY):
		var attacker: CardDefinition = board.get_card(index)
		if attacker == null or attacker.exhausted or not attacker.can_attack():
			continue

		var target: int = board.nearest_index(index, BattleBoard.Owner.PLAYER)
		if target >= 0 and board.distance(index, target) <= max(1, attacker.attack_range):
			var defender: CardDefinition = board.get_card(target)
			attacker.has_attacked = true
			attacker.has_acted = true
			_damage_unit(defender, attacker.attack)
			_cleanup_boards()
			_event("%s atacó al jugador." % attacker.display_name)
			_check_finished()
			if finished:
				return

	_cleanup_boards()

func _enemy_move_units() -> void:
	if enemy_etherium < MOVE_ETHERIUM_COST or player_hero == null or not player_hero.alive():
		return

	while enemy_etherium >= MOVE_ETHERIUM_COST:
		var best_source: int = -1
		var best_target: int = -1
		var best_distance: int = board.distance(0, player_hero_slot)

		for index in board.indices_for_owner(BattleBoard.Owner.ENEMY):
			var unit: CardDefinition = board.get_card(index)
			if unit == null or unit.exhausted or not unit.is_unit() or unit.movement <= 0:
				continue
			for destination in range(BattleBoard.CELL_COUNT):
				if not board.can_move(index, destination, BattleBoard.Owner.ENEMY, unit.movement):
					continue
				var candidate_distance: int = board.distance(destination, player_hero_slot)
				if best_source < 0 or candidate_distance < best_distance:
					best_source = index
					best_target = destination
					best_distance = candidate_distance

		if best_source < 0 or best_target < 0:
			break

		var moved_unit: CardDefinition = board.get_card(best_source)
		if moved_unit == null or not board.move(best_source, best_target, BattleBoard.Owner.ENEMY, moved_unit.movement):
			break
		enemy_etherium -= MOVE_ETHERIUM_COST
		_event("%s avanzó por %d Eterium." % [moved_unit.display_name, MOVE_ETHERIUM_COST])

func _resolve_enemy_non_unit(card: CardDefinition) -> bool:
	match card.effect_kind:
		"damage":
			var target: int = -1
			for index in board.indices_for_owner(BattleBoard.Owner.PLAYER):
				if index != player_hero_slot:
					target = index
					break
			if target >= 0:
				_damage_unit(board.get_card(target), card.effect_value)
				_cleanup_boards()
			else:
				_damage_unit(player_hero, card.effect_value)
			_event("El enemigo usó %s." % card.display_name)
			_check_finished()
			return true
		"buff":
			var target: int = -1
			for index in board.indices_for_owner(BattleBoard.Owner.ENEMY):
				if index != enemy_hero_slot:
					target = index
					break
			if target < 0:
				return false
			var unit: CardDefinition = board.get_card(target)
			unit.attack += card.effect_value
			unit.health += card.effect_secondary
			_event("El enemigo reforzó una unidad.")
			return true
	return false

func _check_finished() -> void:
	if finished:
		return
	_sync_health_mirrors()
	if enemy_hero == null or enemy_hero.health <= 0:
		finished = true
		winner_is_player = true
		_event("La Reina enemiga fue derrotada.")
		battle_finished.emit(true)
	elif player_hero == null or player_hero.health <= 0:
		finished = true
		winner_is_player = false
		_event("El Rey aliado fue derrotado.")
		battle_finished.emit(false)

func _event(message: String) -> void:
	event_occurred.emit(message)

func is_finished() -> bool:
	return finished

func player_won() -> bool:
	return finished and winner_is_player
