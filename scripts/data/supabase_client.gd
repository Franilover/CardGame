class_name GarliaSupabaseClient
extends Node

var last_error := ""
var online := false
var initialized := false
var publishable_key := ""

func _ready() -> void:
	publishable_key = _read_publishable_key()
	initialized = true

func _read_publishable_key() -> String:
	var env_key := OS.get_environment(GarliaSupabaseConfig.ENV_KEY).strip_edges()
	if not env_key.is_empty():
		return env_key

	if FileAccess.file_exists(GarliaSupabaseConfig.KEY_FILE):
		var file := FileAccess.open(GarliaSupabaseConfig.KEY_FILE, FileAccess.READ)
		if file != null:
			return file.get_as_text().strip_edges()

	return ""

func is_configured() -> bool:
	return initialized and not publishable_key.is_empty()

func get_rows(path: String, query: String = "") -> Array:
	last_error = ""

	if not is_configured():
		last_error = "Supabase publishable key no configurada."
		return []

	var request := HTTPRequest.new()
	request.timeout = GarliaSupabaseConfig.REQUEST_TIMEOUT
	add_child(request)

	var url := GarliaSupabaseConfig.PROJECT_URL + "/rest/v1/" + path + query
	var headers: PackedStringArray([
		"apikey: " + publishable_key,
		"Accept: application/json"
	])

	var error: Error = request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		last_error = "HTTPRequest error %d" % error
		request.queue_free()
		return []

	var response: Array = await request.request_completed
	request.queue_free()

	var response_code: int = response[1]
	var body: PackedByteArray = response[3]

	if response_code < 200 or response_code >= 300:
		last_error = "Supabase HTTP %d" % response_code
		online = false
		return []

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Array:
		last_error = "Respuesta inesperada para %s" % path
		online = false
		return []

	online = true
	return parsed

func get_table_rows(table: String, select: String, limit: int = 50) -> Array:
	return await get_rows(table, "?select=%s&limit=%d" % [select, limit])
