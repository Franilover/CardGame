extends PanelContainer

signal card_dropped(slot_index: int, data: Dictionary)
signal slot_activated(slot_index: int)

var card_id: String = ""
var slot_index: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if card_id.is_empty():
		return null
	var preview := Label.new()
	preview.text = card_id
	preview.add_theme_color_override("font_color", Color("#E0EEE5"))
	preview.add_theme_stylebox_override("normal", _preview_style())
	set_drag_preview(preview)
	return {"card_id": card_id, "source_slot": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return slot_index >= 0 and data is Dictionary and not str(data.get("card_id", "")).is_empty()

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		card_dropped.emit(slot_index, data)

func _on_gui_input(event: InputEvent) -> void:
	if slot_index >= 0 and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and card_id.is_empty():
		slot_activated.emit(slot_index)

func _preview_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#123B2D")
	style.border_color = Color("#78CEC1")
	style.set_border_width_all(1)
	return style
