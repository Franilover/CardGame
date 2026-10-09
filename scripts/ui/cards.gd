extends Control

@onready var canon_repository: Node = get_node("/root/GarliaCanonRepository")

const MENU_SCENE_PATH := "res://scenes/main_menu.tscn"

@onready var categories: VBoxContainer = $Margin/Columns/Library/Scroll/Grid
@onready var count_label: Label = $Margin/Columns/Library/Header/Count
@onready var source_label: Label = $Margin/Columns/Sidebar/Source
@onready var detail_label: Label = $Margin/Columns/Sidebar/DetailPanel/Detail
@onready var back_button: Button = $Margin/Columns/Sidebar/Back

const CATEGORY_ORDER := [
	{"id": "criaturas", "title": "CRIATURAS", "type": "CRIATURA"},
	{"id": "items", "title": "ITEMS", "type": "ITEM"},
	{"id": "procesos", "title": "PROCESOS", "type": "PROCESO"},
	{"id": "iums", "title": "IUMS", "type": "IUM"},
	{"id": "oris", "title": "ORIS", "type": "ORIS"}
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	canon_repository.canon_online_updated.connect(_on_canon_refreshed)
	_populate()
	back_button.grab_focus()

func _on_canon_refreshed() -> void:
	_populate()

func _populate() -> void:
	var status: String = canon_repository.get_status_text()
	if canon_repository.refresh_in_progress:
		source_label.text = status + " · ACTUALIZANDO..."
	else:
		source_label.text = status

	var total := 0

	for child in categories.get_children():
		child.queue_free()

	for category in CATEGORY_ORDER:
		var category_id: String = str(category["id"])
		var category_title: String = str(category["title"])
		var category_type: String = str(category["type"])
		var rows: Array = canon_repository.get_table(category_id)
		var entries: Array = _make_entries_from_rows(rows, category_type)

		if entries.is_empty():
			continue

		total += entries.size()
		categories.add_child(_make_category_section(category_title, entries))

	if total == 0:
		source_label.text = "SUPABASE SIN DATOS CANÓNICOS"
		detail_label.text = "El catálogo se carga desde Supabase. Conéctate y vuelve a abrir esta sección para sincronizarlo."
	count_label.text = "%d" % total

func _make_entries_from_rows(rows: Array, type_name: String) -> Array:
	var entries: Array = []

	for row in rows:
		if not row is Dictionary:
			continue

		var dictionary: Dictionary = row
		var raw_nombre: Variant = dictionary.get("nombre", null)
		var name := ""
		if raw_nombre != null:
			name = str(raw_nombre).strip_edges()
		if name.is_empty():
			var raw_id: Variant = dictionary.get("id", null)
			if raw_id != null:
				name = str(raw_id).strip_edges()
		if name.is_empty():
			name = type_name

		var description := str(dictionary.get(
			"descripcion",
			dictionary.get(
				"detalle",
				dictionary.get(
					"transformacion",
					dictionary.get("formula", "")
				)
			)
		))

		entries.append({
			"name": name,
			"type": type_name,
			"description": description,
			"attack": 0,
			"health": 0,
			"cost": 0
		})

	return entries

func _make_category_section(title: String, entries: Array) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	section.add_theme_constant_override("separation", 6)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color("#78CEC1"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	var category_count := Label.new()
	category_count.text = "%d" % entries.size()
	category_count.add_theme_font_size_override("font_size", 11)
	category_count.add_theme_color_override("font_color", Color("#7FAF99"))
	category_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(category_count)

	section.add_child(header)

	var separator := HSeparator.new()
	separator.add_theme_color_override("separator", Color("#2C6651"))
	section.add_child(separator)

	var card_grid := GridContainer.new()
	card_grid.columns = 3
	card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_grid.add_theme_constant_override("h_separation", 6)
	card_grid.add_theme_constant_override("v_separation", 6)
	section.add_child(card_grid)

	for entry in entries:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 82)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.add_theme_font_size_override("font_size", 13)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = str(entry.get("name", "CARTA"))
		button.pressed.connect(_show_detail.bind(entry))
		card_grid.add_child(button)

	return section

func _show_detail(entry: Dictionary) -> void:
	var stats: String = ""
	if int(entry.get("attack", 0)) > 0 or int(entry.get("health", 0)) > 0:
		stats = "\n\n%d ATQ  ·  %d VIDA  ·  %d E" % [
			int(entry.get("attack", 0)),
			int(entry.get("health", 0)),
			int(entry.get("cost", 0))
		]

	detail_label.text = "%s\n\n%s%s\n\n%s" % [
		entry.get("name", "Carta"),
		entry.get("type", ""),
		stats,
		entry.get("description", "")
	]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		_on_back_pressed()
