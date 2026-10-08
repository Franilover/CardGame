class_name BattleEvent
extends RefCounted

## Evento observable emitido por el motor.
## Será la base para UI, debug, replay y online.

enum EventType {
	COMMAND_ACCEPTED,
	COMMAND_REJECTED,
	COMMAND_RESOLVED,
	CARD_PLAYED,
	ATTACK_RESOLVED,
	TURN_STARTED,
	TURN_ENDED,
	STATE_CHANGED,
	BATTLE_FINISHED,
	DIAGNOSTIC
}

var sequence: int = 0
var command_id: String = ""
var type: int = EventType.DIAGNOSTIC
var message: String = ""
var data: Dictionary = {}

static func create(event_type: int, text: String = "", event_data: Dictionary = {}) -> BattleEvent:
	var event := BattleEvent.new()
	event.type = event_type
	event.message = text
	event.data = event_data.duplicate(true)
	return event

func type_name() -> String:
	match type:
		EventType.COMMAND_ACCEPTED:
			return "COMMAND_ACCEPTED"
		EventType.COMMAND_REJECTED:
			return "COMMAND_REJECTED"
		EventType.COMMAND_RESOLVED:
			return "COMMAND_RESOLVED"
		EventType.CARD_PLAYED:
			return "CARD_PLAYED"
		EventType.ATTACK_RESOLVED:
			return "ATTACK_RESOLVED"
		EventType.TURN_STARTED:
			return "TURN_STARTED"
		EventType.TURN_ENDED:
			return "TURN_ENDED"
		EventType.STATE_CHANGED:
			return "STATE_CHANGED"
		EventType.BATTLE_FINISHED:
			return "BATTLE_FINISHED"
		EventType.DIAGNOSTIC:
			return "DIAGNOSTIC"
	return "UNKNOWN"