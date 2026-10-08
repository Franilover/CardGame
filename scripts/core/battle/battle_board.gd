class_name BattleBoard
extends RefCounted

enum Owner {
	NONE,
	PLAYER,
	ENEMY
}

const COLUMNS: int = 5
const ROWS: int = 8
const CELL_COUNT: int = COLUMNS * ROWS
const ENEMY_ZONE_MAX_ROW: int = 2
const PLAYER_ZONE_MIN_ROW: int = 5
const ENEMY_HERO_SLOT: int = COLUMNS / 2
const PLAYER_HERO_SLOT: int = (ROWS - 1) * COLUMNS + COLUMNS / 2

var occupants: Array[CardDefinition] = []
var owners: Array[int] = []
var terrain_ids: Array[String] = []
var blocked: Array[bool] = []

func _init() -> void:
	reset()

func reset() -> void:
	occupants.clear()
	owners.clear()
	terrain_ids.clear()
	blocked.clear()
	for index in range(CELL_COUNT):
		occupants.append(null)
		owners.append(Owner.NONE)
		terrain_ids.append("normal")
		blocked.append(false)

func is_valid_index(index: int) -> bool:
	return index >= 0 and index < CELL_COUNT

static func index_from_position_static(position: Vector2i) -> int:
	if position.x < 0 or position.x >= COLUMNS:
		return -1
	if position.y < 0 or position.y >= ROWS:
		return -1
	return position.y * COLUMNS + position.x

func index_from_position(position: Vector2i) -> int:
	return index_from_position_static(position)

func position_from_index(index: int) -> Vector2i:
	if not is_valid_index(index):
		return Vector2i(-1, -1)
	return Vector2i(index % COLUMNS, index / COLUMNS)

func is_enemy_zone(index: int) -> bool:
	var position := position_from_index(index)
	return position.y >= 0 and position.y <= ENEMY_ZONE_MAX_ROW

func is_player_zone(index: int) -> bool:
	var position := position_from_index(index)
	return position.y >= PLAYER_ZONE_MIN_ROW and position.y < ROWS

func is_player_back_row(index: int) -> bool:
	var position := position_from_index(index)
	return position.y == ROWS - 1

func is_neutral_zone(index: int) -> bool:
	var position := position_from_index(index)
	return position.y == 3 or position.y == 4

func is_hero_slot(index: int) -> bool:
	return index == ENEMY_HERO_SLOT or index == PLAYER_HERO_SLOT

func hero_slot(owner: int) -> int:
	if owner == Owner.PLAYER:
		return PLAYER_HERO_SLOT
	if owner == Owner.ENEMY:
		return ENEMY_HERO_SLOT
	return -1

func is_empty(index: int) -> bool:
	return is_valid_index(index) and occupants[index] == null

func get_card(index: int) -> CardDefinition:
	if not is_valid_index(index):
		return null
	return occupants[index]

func get_owner(index: int) -> int:
	if not is_valid_index(index):
		return Owner.NONE
	return owners[index]

func can_place(index: int, owner: int) -> bool:
	if not is_valid_index(index) or blocked[index] or occupants[index] != null or is_hero_slot(index):
		return false
	if owner == Owner.PLAYER:
		return is_player_zone(index)
	if owner == Owner.ENEMY:
		return is_enemy_zone(index)
	return false

func can_place_hero(index: int, owner: int) -> bool:
	if not is_valid_index(index) or blocked[index] or occupants[index] != null:
		return false
	return index == hero_slot(owner)

func place(index: int, card: CardDefinition, owner: int) -> bool:
	if card == null or not can_place(index, owner):
		return false
	occupants[index] = card
	owners[index] = owner
	return true

func place_hero(index: int, card: CardDefinition, owner: int) -> bool:
	if card == null or not can_place_hero(index, owner):
		return false
	occupants[index] = card
	owners[index] = owner
	return true

func remove(index: int) -> CardDefinition:
	if not is_valid_index(index):
		return null
	var card: CardDefinition = occupants[index]
	occupants[index] = null
	owners[index] = Owner.NONE
	return card

func can_move(index_from: int, index_to: int, owner: int, movement: int) -> bool:
	if not is_valid_index(index_from) or not is_valid_index(index_to):
		return false
	if index_from == index_to or blocked[index_to] or occupants[index_to] != null:
		return false
	if owners[index_from] != owner:
		return false

	var moving_card: CardDefinition = occupants[index_from]
	if moving_card == null or movement <= 0:
		return false

	if is_hero_slot(index_from):
		if moving_card.card_type != CardDefinition.CardType.CHARACTER or index_from != hero_slot(owner):
			return false

	if is_hero_slot(index_to):
		if moving_card.card_type != CardDefinition.CardType.CHARACTER or index_to != hero_slot(owner):
			return false

	return distance(index_from, index_to) <= movement

func move(index_from: int, index_to: int, owner: int, movement: int) -> bool:
	if not can_move(index_from, index_to, owner, movement):
		return false
	var card: CardDefinition = occupants[index_from]
	occupants[index_from] = null
	owners[index_from] = Owner.NONE
	occupants[index_to] = card
	owners[index_to] = owner
	return true

func front_attack_indices(origin_index: int, direction: Vector2i) -> Array[int]:
	var origin: Vector2i = position_from_index(origin_index)
	if origin.x < 0 or origin.y < 0:
		return []
	if abs(direction.x) + abs(direction.y) != 1:
		return []

	var perpendicular := Vector2i(-direction.y, direction.x)
	var result: Array[int] = []
	for offset in [-1, 0, 1]:
		var cell_position: Vector2i = origin + direction + perpendicular * offset
		var index: int = index_from_position_static(cell_position)
		if index >= 0:
			result.append(index)
	return result

func distance(index_a: int, index_b: int) -> int:
	var a := position_from_index(index_a)
	var b := position_from_index(index_b)
	if a.x < 0 or b.x < 0:
		return 9999
	return max(abs(a.x - b.x), abs(a.y - b.y))

func indices_for_owner(owner: int) -> Array[int]:
	var result: Array[int] = []
	for index in range(CELL_COUNT):
		if owners[index] == owner and occupants[index] != null:
			result.append(index)
	return result

func first_empty_in_zone(owner: int) -> int:
	for index in range(CELL_COUNT):
		if can_place(index, owner):
			return index
	return -1

func first_index_for_owner(owner: int) -> int:
	for index in range(CELL_COUNT):
		if owners[index] == owner and occupants[index] != null:
			return index
	return -1

func nearest_index(origin: int, owner: int) -> int:
	var nearest := -1
	var best_distance: int = 9999
	for index in indices_for_owner(owner):
		var current_distance: int = distance(origin, index)
		if current_distance < best_distance:
			best_distance = current_distance
			nearest = index
	return nearest

func occupied_count(owner: int) -> int:
	return indices_for_owner(owner).size()
