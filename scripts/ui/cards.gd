extends Control

const MENU_SCENE_PATH := "res://scenes/main_menu.tscn"

@onready var grid: GridContainer = $Margin/Columns/Library/Scroll/Grid
@onready var count_label: Label = $Margin/Columns/Library/Header/Count
@onready var source_label: Label = $Margin/Columns/Sidebar/Source
@onready var detail_label: Label = $Margin/Columns/Sidebar/DetailPanel/Detail
@onready var back_button: Button = $Margin/Columns/Sidebar/Back

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate()
	back_button.grab_focus()

func _populate() -> void:
	source_label.text = CanonRepository.get_status_text()

	var entries: Array = []
	var canonical_cards := CardCatalog.from_canon(CanonRepository)

	if not canonical_cards.is_empty():
		for card in canonical_cards:
			entries.append({
				"name": card.display_name,
				"type": card.type_name(),
				"description": card.description,
				"attack": card.attack,
				"health": card.health,
				"cost": card.cost,
				"canonical": card.canonical_table
			})
	else:
		source_label.text = "CATÁLOGO LOCAL"
		for card in CardCatalog.starter_deck():
			entries.append({
				"name": card.display_name,
				"type": card.type_name(),
				"description": card.description,
				"attack": card.attack,
				"health": card.health,
				"cost": card.cost,
				"canonical": "local"
			})

	count_label.text = "%d" % entries.size()

	for child in grid.get_children():
		child.queue_free()

	for entry in entries:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 82)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 11)
		button.text = "%s\\n%s" % [entry["name"], entry["type"]]
		button.pressed.connect(_show_detail.bind(entry))
		grid.add_child(button)

func _show_detail(entry: Dictionary) -> void:
	var stats := ""
	if int(entry.get("attack", 0)) > 0 or int(entry.get("health", 0)) > 0:
		stats = "\n\n%d ATQ  ·  %d VIDA  ·  %d E" % [
			int(entry.get("attack", 0)),
			int(entry.get("health", 0)),
			int(entry.get("cost", 0))
		]

	detail_label.text = "%s\\n\\n%s%s\\n\\n%s" % [
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
