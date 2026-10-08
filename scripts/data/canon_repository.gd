class_name GarliaCanonRepository
extends Node

const CACHE_PATH := "user://garlia_cardgame_canon.json"

var loaded := false
var online_loaded := false
var data: Dictionary = {
	"criaturas": [],
	"items": [],
	"items_game": [],
	"iums": [],
	"oris": [],
	"procesos": [],
	"personajes_game": [],
	"reinos_game": []
}

func initialize() -> bool:
	if loaded:
		return online_loaded

	_load_cache()

	if not GarliaSupabaseClient.is_configured():
		loaded = true
		return false

	var creatures_task: Variant = GarliaSupabaseClient.get_table_rows(
		"criaturas",
		"id,nombre,descripcion,imagen_url,stats_dnd,biologia_calculada,ia_config",
		60
	)
	var items_task: Variant = GarliaSupabaseClient.get_table_rows(
		"items",
		"id,nombre,imagen_url,descripcion,origen,propiedades_fisicas,publicado",
		80
	)
	var items_game_task: Variant = GarliaSupabaseClient.get_table_rows(
		"items_game",
		"id,item_id,tipo,max_stack,propiedades",
		80
	)
	var iums_task: Variant = GarliaSupabaseClient.get_table_rows(
		"iums",
		"id,orden,nombre,detalle,extra",
		40
	)
	var oris_task: Variant = GarliaSupabaseClient.get_table_rows(
		"oris",
		"id,orden,nombre,familia,formula,dominio,descripcion",
		20
	)
	var processes_task: Variant = GarliaSupabaseClient.get_table_rows(
		"procesos",
		"id,nombre,tipo,descripcion,regla_clave,entrada,transformacion,salida,estado_fundamento",
		40
	)
	var characters_task: Variant = GarliaSupabaseClient.get_table_rows(
		"personajes_game",
		"id,nombre,criatura_id,activo,personaje_id,reino_game_id",
		40
	)
	var kingdoms_task: Variant = GarliaSupabaseClient.get_table_rows(
		"reinos_game",
		"id,reino_id,clave,activo,orden,propiedades",
		30
	)

	var successful := 0
	var results: Array = [
		await creatures_task,
		await items_task,
		await items_game_task,
		await iums_task,
		await oris_task,
		await processes_task,
		await characters_task,
		await kingdoms_task
	]

	var keys: Array[String] = [
		"criaturas",
		"items",
		"items_game",
		"iums",
		"oris",
		"procesos",
		"personajes_game",
		"reinos_game"
	]

	for i in range(keys.size()):
		if results[i] is Array and not results[i].is_empty():
			data[keys[i]] = results[i]
			successful += 1

	if successful > 0:
		online_loaded = true
		_save_cache()

	loaded = true
	return online_loaded

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
	return not get_table("criaturas").is_empty() 		or not get_table("iums").is_empty() 		or not get_table("procesos").is_empty()

func get_status_text() -> String:
	if online_loaded:
		return "CANON SINCRONIZADO"
	if has_canon_data():
		return "CANON EN CACHÉ"
	if GarliaSupabaseClient.is_configured():
		return "SIN DATOS REMOTOS"
	return "CATÁLOGO LOCAL"
