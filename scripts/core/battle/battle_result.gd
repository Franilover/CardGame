class_name BattleResult
extends RefCounted

## Resultado de una orden. No ejecuta lógica de gameplay.

var success: bool = false
var code: String = "UNKNOWN"
var message: String = ""
var command_id: String = ""
var event_sequence: int = -1
var data: Dictionary = {}

static func ok(message_text: String = "OK") -> BattleResult:
	var result := BattleResult.new()
	result.success = true
	result.code = "OK"
	result.message = message_text
	return result

static func error(error_code: String, message_text: String) -> BattleResult:
	var result := BattleResult.new()
	result.success = false
	result.code = error_code
	result.message = message_text
	return result

func describe() -> String:
	return "%s: %s" % [code, message]