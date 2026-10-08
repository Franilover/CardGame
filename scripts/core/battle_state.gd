class_name BattleState
extends RefCounted

signal state_changed
signal event_occurred(message: String)
signal battle_finished(player_won: bool)

const PLAYER_SLOTS := 9
const ENEMY_SLOTS := 9
const GRID_COLUMNS := 3
const MAX_HAND := 8
const START_HAND := 5
const ACTIONS_PER_TURN := 3
const MAX_ETHERIUM := 10

var turn: int = 1
var player_actions: int = ACTIONS_PER_TURN
var player_etherium: int = 3
var player_max_etherium: int = 3
var enemy_etherium: int = 3
var enemy_max_etherium: int = 3
var player_health: int = 30
var enemy_health: int = 30

var player_board: Array[CardDefinition] = []
var enemy_board: Array[CardDefinition] = []
var hand: Array[CardDefinition] = []
var deck: Array[CardDefinition] = []
var discard: Array[CardDefinition] = []
var enemy_deck: Array[CardDefinition] = []
var enemy_discard: Array[CardDefinition] = []

var finished := false
var winner_is_player := false
var fatigue_damage := 1

func reset() -> void:
	turn = 1
	player_actions = ACTIONS_PER_TURN
	player_etherium = 3
	player_max_etherium = 3
	enemy_etherium = 3
	enemy_max_etherium = 3
	player_health = 30
	enemy_health = 30
	finished = false
	winner_is_player = false
	fatigue_damage = 1

	player_board.clear()
	enemy_board.clear()
	hand.clear()
	deck.clear()
	discard.clear()
	enemy_deck.clear()
	enemy_discard.clear()

	for i in range(PLAYER_SLOTS):
		player_board.append(null)
	for i in range(ENEMY_SLOTS):
		enemy_board.append(null)

	state_changed.emit()

func setup(player_cards: Array[CardDefinition], enemy_cards: Array[CardDefinition]) -> void:
	reset()
	deck = _runtime_copies(player_cards)
	enemy_deck = _runtime_copies(enemy_cards)
	deck.shuffle()
	enemy_deck.shuffle()

	for i in range(START_HAND):
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
		fatigue_damage = max(1, fatigue_damage)
		player_health = max(0, player_health - fatigue_damage)
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
		if slot < 0 or slot >= PLAYER_SLOTS or player_board[slot] != null:
			return false
		player_board[slot] = card
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
			if target_enemy or target_slot < 0 or target_slot >= PLAYER_SLOTS:
				return false
			var unit: CardDefinition = player_board[target_slot]
			if unit == null:
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
			if target_enemy and target_slot >= 0 and target_slot < ENEMY_SLOTS and enemy_board[target_slot] != null:
				var enemy_unit: CardDefinition = enemy_board[target_slot]
				_damage_unit(enemy_unit, card.effect_value, true)
			else:
				enemy_health = max(0, enemy_health - card.effect_value)
			_event("%s hizo %d de daño." % [card.display_name, card.effect_value])
			return true

		"damage_all":
			for i in range(ENEMY_SLOTS):
				if enemy_board[i] != null:
					_damage_unit(enemy_board[i], card.effect_value, true)
			enemy_health = max(0, enemy_health - card.effect_secondary)
			_event("%s afectó todo el campo enemigo." % card.display_name)
			return true

	return false

func attack_unit(player_slot: int, enemy_slot: int = -1) -> bool:
	if finished or player_actions <= 0:
		return false
	if player_slot < 0 or player_slot >= PLAYER_SLOTS:
		return false

	var attacker: CardDefinition = player_board[player_slot]
	if attacker == null or not attacker.can_attack():
		return false

	attacker.has_attacked = true
	player_actions -= 1

	if enemy_slot >= 0 and enemy_slot < ENEMY_SLOTS and enemy_board[enemy_slot] != null:
		var defender: CardDefinition = enemy_board[enemy_slot]
		_damage_unit(defender, attacker.attack, true)
		_damage_unit(attacker, defender.attack, false)
		_event("%s atacó." % attacker.display_name)
	else:
		enemy_health = max(0, enemy_health - attacker.attack)
		_event("%s golpeó al enemigo." % attacker.display_name)

	_cleanup_boards()
	_check_finished()
	state_changed.emit()
	return true

func _damage_unit(unit: CardDefinition, amount: int, is_enemy_unit: bool) -> void:
	if unit == null:
		return

	var remaining: int = amount
	if unit.armor > 0:
		var absorbed: int = min(unit.armor, remaining)
		unit.armor -= absorbed
		remaining -= absorbed

	unit.health -= max(0, remaining)

func _cleanup_boards() -> void:
	for i in range(PLAYER_SLOTS):
		if player_board[i] != null and not player_board[i].alive():
			discard.append(player_board[i])
			player_board[i] = null

	for i in range(ENEMY_SLOTS):
		if enemy_board[i] != null and not enemy_board[i].alive():
			enemy_discard.append(enemy_board[i])
			enemy_board[i] = null

func end_turn() -> void:
	if finished:
		return

	for unit in player_board:
		if unit != null:
			unit.exhausted = false
			unit.has_attacked = false

	_enemy_turn()

	if finished:
		return

	turn += 1
	player_max_etherium = min(MAX_ETHERIUM, player_max_etherium + 1)
	player_etherium = player_max_etherium
	player_actions = ACTIONS_PER_TURN
	draw_card()
	_cleanup_boards()
	state_changed.emit()

func _enemy_turn() -> void:
	enemy_max_etherium = min(MAX_ETHERIUM, enemy_max_etherium + 1)
	enemy_etherium = enemy_max_etherium
	var actions := ACTIONS_PER_TURN

	while actions > 0:
		var played := false
		var best_card: CardDefinition = null
		var best_index := -1

		for i in range(enemy_deck.size()):
			var candidate: CardDefinition = enemy_deck[i]
			if candidate.cost > enemy_etherium:
				continue

			if candidate.is_unit():
				if _first_empty_enemy_slot() >= 0 and (best_card == null or candidate.cost < best_card.cost):
					best_card = candidate
					best_index = i
			elif best_card == null:
				best_card = candidate
				best_index = i

		if best_card != null:
			if best_card.is_unit():
				var slot := _first_empty_enemy_slot()
				if slot >= 0:
					best_card = enemy_deck.pop_at(best_index)
					enemy_board[slot] = best_card
					enemy_etherium -= best_card.cost
					actions -= 1
					played = true
					_event("El enemigo jugó %s." % best_card.display_name)
			else:
				best_card = enemy_deck.pop_at(best_index)
				if _resolve_enemy_non_unit(best_card):
					enemy_etherium -= best_card.cost
					actions -= 1
					played = true
					enemy_discard.append(best_card)

		if not played:
			break

	for i in range(ENEMY_SLOTS):
		if enemy_board[i] == null:
			continue

		var attacker: CardDefinition = enemy_board[i]
		if attacker.health <= 0:
			continue

		var target: CardDefinition = player_board[i]
		if target != null:
			_damage_unit(target, attacker.attack, false)
		else:
			player_health = max(0, player_health - attacker.attack)

		attacker.has_attacked = true
		_cleanup_boards()
		_check_finished()

		if finished:
			return

func _resolve_enemy_non_unit(card: CardDefinition) -> bool:
	match card.effect_kind:
		"damage":
			var target := _first_player_unit()
			if target >= 0:
				_damage_unit(player_board[target], card.effect_value, false)
				_cleanup_boards()
			else:
				player_health = max(0, player_health - card.effect_value)
			_event("El enemigo usó %s." % card.display_name)
			_check_finished()
			return true

		"buff":
			var target := _first_enemy_unit()
			if target < 0:
				return false
			var unit: CardDefinition = enemy_board[target]
			unit.attack += card.effect_value
			unit.health += card.effect_secondary
			_event("El enemigo reforzó una unidad.")
			return true

	return false

func _first_player_unit() -> int:
	for i in range(PLAYER_SLOTS):
		if player_board[i] != null:
			return i
	return -1

func _first_enemy_unit() -> int:
	for i in range(ENEMY_SLOTS):
		if enemy_board[i] != null:
			return i
	return -1

func _first_empty_enemy_slot() -> int:
	for i in range(ENEMY_SLOTS):
		if enemy_board[i] == null:
			return i
	return -1

func _check_finished() -> void:
	if finished:
		return

	if enemy_health <= 0:
		finished = true
		winner_is_player = true
		battle_finished.emit(true)
	elif player_health <= 0:
		finished = true
		winner_is_player = false
		battle_finished.emit(false)

func _event(message: String) -> void:
	event_occurred.emit(message)

func is_finished() -> bool:
	return finished

func player_won() -> bool:
	return finished and winner_is_player
