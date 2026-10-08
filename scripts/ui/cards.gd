extends Control

const MENU_SCENE_PATH := "res://scenes/main_menu.tscn"

@onready var grid: GridContainer = $Margin/Columns/Library/Scroll/Grid
@onready var count_label: Label = $Margin/Columns/Library/Header/Count
@onready var source_label: Label = $Margin/Columns/Sidebar/Source
@onready var detail_label: Label = $Margin/Columns/Sidebar/Detail
@onready var back_button: Button = $Margin/Columns/Sidebar/Back

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate()
	back_button.grab_focus()

func _populate() -> void:
	source_label.text = CanonRepository.get_status_text()

	var entries: Array = []
	entries.append_array(_tag_rows(CanonRepository.get_table("criaturas"), "CRIATURA"))
	entries.append_array(_tag_rows(CanonRepository.get_table("items"), "OBJETO"))
	entries.append_array(_tag_rows(CanonRepository.get_table("iums"), "IUM"))
	entries.append_array(_tag_rows(CanonRepository.get_table("procesos"), "PROCESO"))
	entries.append_array(_tag_rows(CanonRepository.get_table("oris"), "ORIS"))

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

func _tag_rows(rows: Array, type_name: String) -> Array:
	var result: Array = []
	for row in rows:
		if row is Dictionary:
			result.append({
				"name": str(row.get("nombre", type_name)),
				"type": type_name,
				"description": str(row.get("descripcion", row.get("extra", row.get("detalle", row.get("formula", "")))))
			})
	return result

func _show_detail(entry: Dictionary) -> void:
	detail_label.text = "%s\\n\\n%s\\n\\n%s" % [
		entry.get("name", "Carta"),
		entry.get("type", ""),
		entry.get("description", "")
	]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		_on_back_pressed()
