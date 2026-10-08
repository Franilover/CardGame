class_name BattleCommand
extends RefCounted

## Comando declarativo enviado al BattleEngine.
## La UI expresa intenciones; nunca modifica BattleState directamente.

enum CommandType {
	PLAY_CARD,
	ATTACK,
	HERO_ATTACK,
	MOVE_UNIT,
	MIXER_PLACE,
	MIXER_PLACE_CATALOG_IUM,
	MIXER_REMOVE,
	MIXER_RESOLVE,
	END_TURN,
	SURRENDER
}

var request_id: String = ""
var type: int = CommandType.END_TURN
var hand_index: int = -1
var catalog_index: int = -1
var attacker_slot: int = -1
var target_slot: int = -1
var mixer_slot: int = -1
var target_enemy: bool = false
var direction: Vector2i = Vector2i.ZERO
var metadata: Dictionary = {}

static func play_card(index: int, slot: int = -1, enemy_target: bool = false) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = CommandType.PLAY_CARD
	command.hand_index = index
	command.target_slot = slot
	command.target_enemy = enemy_target
	return command

static func attack(attacker: int, target: int = -1) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = CommandType.ATTACK
	command.attacker_slot = attacker
	command.target_slot = target
	return command

static func hero_attack(attacker: int, attack_direction: Vector2i) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = CommandType.HERO_ATTACK
	command.attacker_slot = attacker
	command.direction = attack_direction
	return command

static func move_unit(attacker: int, target: int) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = CommandType.MOVE_UNIT
	command.attacker_slot = attacker
	command.target_slot = target
	return command

static func mixer_place(index: int, slot: int) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = CommandType.MIXER_PLACE
	command.hand_index = index
	command.mixer_slot = slot
	return command

static func mixer_catalog_place(index: int, slot: int) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = CommandType.MIXER_PLACE_CATALOG_IUM
	command.catalog_index = index
	command.mixer_slot = slot
	return command

static func mixer_remove(slot: int) -> BattleCommand:
	var command := BattleCommand.new()
	command.type = CommandType.MIXER_REMOVE
	command.mixer_slot = slot
	return command

static func mixer_resolve() -> BattleCommand:
	var command := BattleCommand.new()
	command.type = CommandType.MIXER_RESOLVE
	return command

static func end_turn() -> BattleCommand:
	var command := BattleCommand.new()
	command.type = CommandType.END_TURN
	return command

static func surrender() -> BattleCommand:
	var command := BattleCommand.new()
	command.type = CommandType.SURRENDER
	return command

func type_name() -> String:
	match type:
		CommandType.PLAY_CARD:
			return "PLAY_CARD"
		CommandType.ATTACK:
			return "ATTACK"
		CommandType.HERO_ATTACK:
			return "HERO_ATTACK"
		CommandType.MOVE_UNIT:
			return "MOVE_UNIT"
		CommandType.MIXER_PLACE:
			return "MIXER_PLACE"
		CommandType.MIXER_PLACE_CATALOG_IUM:
			return "MIXER_PLACE_CATALOG_IUM"
		CommandType.MIXER_REMOVE:
			return "MIXER_REMOVE"
		CommandType.MIXER_RESOLVE:
			return "MIXER_RESOLVE"
		CommandType.END_TURN:
			return "END_TURN"
		CommandType.SURRENDER:
			return "SURRENDER"
	return "UNKNOWN"
