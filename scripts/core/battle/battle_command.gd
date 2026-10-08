class_name BattleCommand
extends RefCounted

## Comando declarativo de alto nivel enviado al BattleEngine.

enum CommandType {
	PLAY_CARD,
	ATTACK,
	END_TURN,
	SURRENDER
}

var request_id: String = ""
var type: int = CommandType.END_TURN
var hand_index: int = -1
var attacker_slot: int = -1
var target_slot: int = -1
var target_enemy: bool = false
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
		CommandType.END_TURN:
			return "END_TURN"
		CommandType.SURRENDER:
			return "SURRENDER"
	return "UNKNOWN"
