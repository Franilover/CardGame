extends Node

signal canon_online_updated

@onready var supabase_client: Node = get_node("/root/GarliaSupabaseClient")

const CACHE_PATH := "user://garlia_cardgame_canon.json"

var loaded := false
var online_loaded := false
var refresh_in_progress := false
var data: Dictionary = {
	"criaturas": [],
	"items": [],
	"items_game": [],
	"iums": [],
	"oris": [],
	"procesos": [],
	"personajes_game": [],
	"reinos_game": [],
	"cardgame_reglas_v1": []
}

func initialize() -> bool:
	if loaded:
		return online_loaded

	_load_cache()

	if not _has_cached_data():
		if not supabase_client.is_configured():
			loaded = true
			return false

		var online: bool = await _refresh_online()
		loaded = true
		return online

	loaded = true

	if supabase_client.is_configured():
		call_deferred("_refresh_online")

	return online_loaded

func _refresh_online() -> bool:
	if refresh_in_progress:
		return online_loaded

	refresh_in_progress = true

	var successful := 0
	var table_requests: Array[Dictionary] = [
		{"key": "criaturas", "select": "id,nombre,descripcion,imagen_url,stats_dnd,ia_config", "limit": 60},
		{"key": "items", "select": "id,nombre,imagen_url,descripcion,origen,propiedades_fisicas,publicado", "limit": 80},
		{"key": "items_game", "select": "id,item_id,tipo,max_stack,propiedades", "limit": 80},
		{"key": "iums", "select": "id,orden,nombre,detalle,extra", "limit": 40},
		{"key": "oris", "select": "id,orden,nombre,familia,formula,dominio,descripcion", "limit": 20},
		{"key": "procesos", "select": "id,nombre,tipo,descripcion,regla_clave,entrada,transformacion,salida,estado_fundamento", "limit": 100},
		{"key": "personajes_game", "select": "id,nombre,criatura_id,activo,personaje_id,reino_game_id", "limit": 40},
		{"key": "reinos_game", "select": "id,reino_id,clave,activo,orden,propiedades", "limit": 30},
		{"key": "cardgame_reglas_v1", "select": "clave,configuracion,activo,version", "limit": 10}
	]

	for request_data in table_requests:
		var key: String = str(request_data["key"])
		var rows: Array = await supabase_client.get_table_rows(
			key,
			str(request_data["select"]),
			int(request_data["limit"])
		)
		# Un 200 con [] es un catálogo canónico vacío y debe reemplazar la caché.
		# Un error de red/HTTP conserva la última copia local utilizable.
		if supabase_client.last_error.is_empty():
			data[key] = rows
			successful += 1

	if successful > 0:
		online_loaded = true
		_save_cache()
		canon_online_updated.emit()

	refresh_in_progress = false
	return online_loaded

func _has_cached_data() -> bool:
	for key in data.keys():
		if data[key] is Array and not data[key].is_empty():
			return true
	return false

func _load_cache() -> void:
	if not FileAccess.file_exists(CACHE_PATH):
		return

	var file := FileAccess.open(CACHE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in data.keys():
			if parsed.has(key) and parsed[key] is Array:
				data[key] = parsed[key]

func _save_cache() -> void:
	var file := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))

func get_table(table_name: String) -> Array:
	return data.get(table_name, []) as Array

func has_canon_data() -> bool:
	return not get_table("criaturas").is_empty() or not get_table("iums").is_empty() or not get_table("procesos").is_empty()

func get_status_text() -> String:
	if online_loaded:
		return "CANON SINCRONIZADO"
	if has_canon_data():
		return "CANON EN CACHÉ"
	if supabase_client.is_configured():
		return "SIN DATOS REMOTOS"
	return "CATÁLOGO LOCAL"
