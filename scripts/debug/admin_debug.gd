extends Node

const PANEL_SIZE := Vector2(1160, 650)
const QUERY_LIMIT := 30

var overlay: CanvasLayer
var panel: PanelContainer
var status_label: Label
var counts_label: Label
var logs_text: TextEdit
var result_text: TextEdit
var query_title: Label
var copy_json_button: Button
var copy_sql_button: Button
var query_buttons: Array[Button] = []
var query_definitions: Array[Dictionary] = [
	{
		"name": "CRIATURAS",
		"table": "criaturas",
		"select": "id,nombre,descripcion,imagen_url,stats_dnd,biologia_calculada,ia_config",
		"limit": QUERY_LIMIT
	},
	{
		"name": "ITEMS",
		"table": "items",
		"select": "id,nombre,imagen_url,descripcion,origen,propiedades_fisicas,publicado",
		"limit": QUERY_LIMIT
	},
	{
		"name": "ITEMS_GAME",
		"table": "items_game",
		"select": "id,item_id,tipo,max_stack,propiedades",
		"limit": QUERY_LIMIT
	},
	{
		"name": "IUMS",
		"table": "iums",
		"select": "id,orden,nombre,detalle,extra",
		"limit": QUERY_LIMIT
	},
	{
		"name": "ORIS",
		"table": "oris",
		"select": "id,orden,nombre,familia,formula,dominio,descripcion",
		"limit": QUERY_LIMIT
	},
	{
		"name": "PROCESOS",
		"table": "procesos",
		"select": "id,nombre,tipo,descripcion,regla_clave,entrada,transformacion,salida,estado_fundamento",
		"limit": QUERY_LIMIT
	},
	{
		"name": "PERSONAJES_GAME",
		"table": "personajes_game",
		"select": "id,nombre,criatura_id,activo,personaje_id,reino_game_id",
		"limit": QUERY_LIMIT
	},
	{
		"name": "REINOS_GAME",
		"table": "reinos_game",
		"select": "id,reino_id,clave,activo,orden,propiedades",
		"limit": QUERY_LIMIT
	}
]

var last_result: Array = []
var last_definition: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	_write_startup_log()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if overlay == null:
		return
	overlay.visible = not overlay.visible
	if overlay.visible:
		_refresh_status()
		_refresh_logs()

func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	panel = PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.add_theme_stylebox_override("panel", _style_box(Color("#081E16"), Color("#4B8E76"), 12, 2))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)

	var title := Label.new()
	title.text = "ADMIN / MONITOR"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#E3C34F"))
	header.add_child(title)

	var hint := Label.new()
	hint.text = "F3 cerrar"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color("#7FAF99"))
	header.add_child(hint)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	root.add_child(toolbar)

	var refresh_button := Button.new()
	refresh_button.text = "ACTUALIZAR ESTADO"
	refresh_button.pressed.connect(_on_refresh_pressed)
	toolbar.add_child(refresh_button)

	var copy_logs_button := Button.new()
	copy_logs_button.text = "COPIAR LOGS"
	copy_logs_button.pressed.connect(_copy_logs)
	toolbar.add_child(copy_logs_button)

	var status_box := PanelContainer.new()
	status_box.custom_minimum_size = Vector2(0, 76)
	status_box.add_theme_stylebox_override("panel", _style_box(Color("#0F3024"), Color("#2C6651"), 8, 1))
	root.add_child(status_box)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 10)
	status_margin.add_theme_constant_override("margin_right", 10)
	status_margin.add_theme_constant_override("margin_top", 7)
	status_margin.add_theme_constant_override("margin_bottom", 7)
	status_box.add_child(status_margin)

	var status_root := VBoxContainer.new()
	status_root.add_theme_constant_override("separation", 3)
	status_margin.add_child(status_root)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 12)
	status_root.add_child(status_label)

	counts_label = Label.new()
	counts_label.add_theme_font_size_override("font_size", 11)
	counts_label.add_theme_color_override("font_color", Color("#7FAF99"))
	status_root.add_child(counts_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 170
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 5)
	body.add_child(left)

	var left_title := Label.new()
	left_title.text = "QUERIES"
	left_title.add_theme_font_size_override("font_size", 11)
	left_title.add_theme_color_override("font_color", Color("#78CEC1"))
	left.add_child(left_title)

	for definition in query_definitions:
		var button := Button.new()
		button.text = definition["name"]
		button.custom_minimum_size = Vector2(0, 32)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_run_query.bind(definition))
		left.add_child(button)
		query_buttons.append(button)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 5)
	body.add_child(right)

	query_title = Label.new()
	query_title.text = "RESULTADO"
	query_title.add_theme_font_size_override("font_size", 12)
	query_title.add_theme_color_override("font_color", Color("#E3C34F"))
	right.add_child(query_title)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 5)
	right.add_child(actions)

	copy_json_button = Button.new()
	copy_json_button.text = "COPIAR JSON"
	copy_json_button.disabled = true
	copy_json_button.pressed.connect(_copy_json)
	actions.add_child(copy_json_button)

	copy_sql_button = Button.new()
	copy_sql_button.text = "COPIAR SQL"
	copy_sql_button.disabled = true
	copy_sql_button.pressed.connect(_copy_sql)
	actions.add_child(copy_sql_button)

	result_text = TextEdit.new()
	result_text.custom_minimum_size = Vector2(0, 300)
	result_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_text.editable = false
	result_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	result_text.add_theme_font_size_override("font_size", 11)
	right.add_child(result_text)

	var logs_title := Label.new()
	logs_title.text = "LOGS"
	logs_title.add_theme_font_size_override("font_size", 12)
	logs_title.add_theme_color_override("font_color", Color("#78CEC1"))
	root.add_child(logs_title)

	logs_text = TextEdit.new()
	logs_text.custom_minimum_size = Vector2(0, 120)
	logs_text.editable = false
	logs_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	logs_text.add_theme_font_size_override("font_size", 10)
	root.add_child(logs_text)

	overlay.visible = false

func _style_box(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func _write_startup_log() -> void:
	_append_log("Monitor iniciado.")
	_append_log("F3 abre/cierra el panel.")
	_refresh_status()

func _refresh_status() -> void:
	var supabase := get_node_or_null("/root/GarliaSupabaseClient")
	var canon := get_node_or_null("/root/GarliaCanonRepository")

	if supabase == null:
		status_label.text = "Supabase: NO ENCONTRADO"
	else:
		var configured: bool = bool(supabase.call("is_configured"))
		var online: bool = bool(supabase.get("online"))
		status_label.text = "Supabase: %s   |   Red: %s" % [
			"CONFIGURADO" if configured else "SIN CLAVE",
			"ONLINE" if online else "OFFLINE"
		]

	if canon == null:
		counts_label.text = "Canon: NO ENCONTRADO"
		return

	var status: String = str(canon.call("get_status_text"))
	var counts: Array[String] = []
	for definition in query_definitions:
		var table_name: String = str(definition["table"])
		var rows_variant: Variant = canon.call("get_table", table_name)
		if rows_variant is Array:
			counts.append("%s %d" % [definition["name"], rows_variant.size()])
	counts_label.text = "Canon: %s   |   %s" % [status, "  ".join(counts)]

func _refresh_logs() -> void:
	if logs_text != null:
		logs_text.text = _get_log_text()

func _append_log(message: String) -> void:
	var line := "[%s] %s" % [Time.get_time_string_from_system(), message]
	var previous := ""
	if logs_text != null:
		previous = logs_text.text
	if previous.is_empty():
		logs_text.text = line
	else:
		logs_text.text = previous + "\n" + line

func _get_log_text() -> String:
	if logs_text == null:
		return ""
	return logs_text.text

func _on_refresh_pressed() -> void:
	_refresh_status()
	_append_log("Estado actualizado.")

func _run_query(definition: Dictionary) -> void:
	last_definition = definition
	query_title.text = "RESULTADO / %s" % str(definition["name"])
	result_text.text = "Consultando..."
	copy_json_button.disabled = true
	copy_sql_button.disabled = true

	var supabase := get_node_or_null("/root/GarliaSupabaseClient")
	if supabase == null:
		result_text.text = "No existe /root/GarliaSupabaseClient."
		_append_log("QUERY fallida: autoload Supabase no encontrado.")
		return

	var configured: bool = bool(supabase.call("is_configured"))
	if not configured:
		result_text.text = "Supabase no está configurado.\n\nConfigura GARLIA_SUPABASE_PUBLISHABLE_KEY o user://garlia_supabase_key.txt."
		_append_log("QUERY bloqueada: Supabase sin clave.")
		return

	var table_name: String = str(definition["table"])
	var select_fields: String = str(definition["select"])
	var limit: int = int(definition["limit"])

	var rows_variant: Variant = await supabase.call("get_table_rows", table_name, select_fields, limit)
	if not rows_variant is Array:
		result_text.text = "Respuesta inválida.\n\nError: %s" % str(supabase.get("last_error"))
		_append_log("QUERY %s ERROR: %s" % [table_name, str(supabase.get("last_error"))])
		return

	last_result = rows_variant
	result_text.text = JSON.stringify(last_result, "\t")
	copy_json_button.disabled = false
	copy_sql_button.disabled = false
	_append_log("QUERY %s OK: %d filas." % [table_name, last_result.size()])
	_refresh_status()

func _copy_json() -> void:
	DisplayServer.clipboard_set(JSON.stringify(last_result, "\t"))
	_append_log("JSON copiado al portapapeles.")

func _copy_sql() -> void:
	if last_definition.is_empty():
		return

	var table_name: String = str(last_definition["table"])
	var select_fields: String = str(last_definition["select"])
	var limit: int = int(last_definition["limit"])
	var sql := "select %s from public.%s limit %d;" % [select_fields, table_name, limit]
	DisplayServer.clipboard_set(sql)
	_append_log("SQL copiado: %s." % table_name)

func _copy_logs() -> void:
	DisplayServer.clipboard_set(_get_log_text())
	_append_log("Logs copiados al portapapeles.")
