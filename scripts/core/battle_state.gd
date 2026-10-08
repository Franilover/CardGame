class_name BattleState
extends RefCounted

signal state_changed

const PLAYER_SLOTS := 3
const ENEMY_SLOTS := 3

var turn: int = 1
var player_etherium: int = 3
var player_max_etherium: int = 3
var enemy_etherium: int = 3
var player_health: int = 30
var enemy_health: int = 30

var player_board: Array[CardDefinition] = []
var enemy_board: Array[CardDefinition] = []
var hand: Array[CardDefinition] = []
var deck: Array[CardDefinition] = []

func reset() -> void:
	turn = 1
	player_etherium = 3
	player_max_etherium = 3
	enemy_etherium = 3
	player_health = 30
	enemy_health = 30
	player_board.clear()
	enemy_board.clear()
	hand.clear()
	deck.clear()
	state_changed.emit()

func draw_card() -> CardDefinition:
	if deck.is_empty():
		return null
	var card: CardDefinition = deck.pop_front()
	hand.append(card)
	state_changed.emit()
	return card

func can_play(card: CardDefinition) -> bool:
	return card != null and card.cost <= player_etherium

func play_card(card: CardDefinition, slot: int = -1) -> bool:
	if not can_play(card):
		return false
	if not hand.has(card):
		return false
	if card.is_unit():
		if slot < 0 or slot >= PLAYER_SLOTS or player_board.size() >= PLAYER_SLOTS:
			return false
		if slot < player_board.size() and player_board[slot] != null:
			return false
		while player_board.size() < PLAYER_SLOTS:
			player_board.append(null)
		player_board[slot] = card
	else:
		_resolve_non_unit(card)
	player_etherium -= card.cost
	hand.erase(card)
	state_changed.emit()
	return true

func _resolve_non_unit(card: CardDefinition) -> void:
	match card.card_type:
		CardDefinition.CardType.PROCESS:
			enemy_health = max(0, enemy_health - 4)
		CardDefinition.CardType.IUM:
			player_max_etherium += 1
			player_etherium += 1
		CardDefinition.CardType.ORIS:
			enemy_health = max(0, enemy_health - 8)
		CardDefinition.CardType.OBJECT:
			if not player_board.is_empty():
				for unit in player_board:
					if unit != null:
						unit.attack += 1

func end_turn() -> void:
	_resolve_player_board()
	_enemy_turn()
	turn += 1
	player_max_etherium = min(10, player_max_etherium + 1)
	player_etherium = player_max_etherium
	enemy_etherium = min(10, enemy_etherium + 1)
	draw_card()
	state_changed.emit()

func _resolve_player_board() -> void:
	for unit in player_board:
		if unit != null:
			enemy_health = max(0, enemy_health - unit.attack)

func _enemy_turn() -> void:
	for unit in enemy_board:
		if unit != null:
			player_health = max(0, player_health - unit.attack)

func is_finished() -> bool:
	return player_health <= 0 or enemy_health <= 0

func player_won() -> bool:
	return enemy_health <= 0 and player_health > 0
