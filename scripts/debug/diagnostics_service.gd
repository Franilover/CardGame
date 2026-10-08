class_name DiagnosticsService
extends Node

## Registro centralizado para que cada sistema deje una huella diagnosticable.

signal entry_added(entry: Dictionary)

const MAX_ENTRIES: int = 500

var entries: Array[Dictionary] = []
var session_id: String = ""
var current_context: String = "BOOT"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_session()

func start_session() -> void:
	entries.clear()
	session_id = "%s-%04d" % [Time.get_date_string_from_system(), Time.get_ticks_msec() % 10000]
	write_entry("INFO", "DIAGNOSTICS", "SESSION_START", "Sesión iniciada.", {
		"session_id": session_id
	})

func set_context(context: String) -> void:
	current_context = context

func write_entry(level: String, system: String, event_name: String, message: String, data: Dictionary = {}) -> void:
	var entry: Dictionary = {
		"timestamp": Time.get_time_string_from_system(),
		"level": level,
		"system": system,
		"event": event_name,
		"context": current_context,
		"message": message,
		"data": data.duplicate(true)
	}
	entries.append(entry)

	if entries.size() > MAX_ENTRIES:
		entries.pop_front()

	entry_added.emit(entry)

func info(system: String, event_name: String, message: String, data: Dictionary = {}) -> void:
	write_entry("INFO", system, event_name, message, data)

func warning(system: String, event_name: String, message: String, data: Dictionary = {}) -> void:
	write_entry("WARN", system, event_name, message, data)

func error(system: String, event_name: String, message: String, data: Dictionary = {}) -> void:
	write_entry("ERROR", system, event_name, message, data)

func get_recent(limit: int = 50) -> Array[Dictionary]:
	var start: int = max(0, entries.size() - limit)
	var result: Array[Dictionary] = []

	for index in range(start, entries.size()):
		result.append(entries[index])

	return result

func export_json() -> String:
	return JSON.stringify({
		"session_id": session_id,
		"entries": entries
	}, "	")
