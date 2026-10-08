extends Node

var state: BattleState
var selected_card: CardDefinition
var hand_buttons: Array[Button] = []
var slot_buttons: Array[Button] = []
var enemy_slots: Array[PanelContainer] = []
var status_label: Label
var enemy_label: Label
var player_label: Label
var etherium_label: Label
var turn_label: Label
var phase_label: Label
var end_turn_button: Button

const BG_COLOR := Color("#071E16")
const SURFACE_COLOR := Color("#0F3024")
const SURFACE_ALT_COLOR := Color("#123B2D")
const BORDER_COLOR := Color("#2C6651")
const TEXT_COLOR := Color("#E0EEE5")
const MUTED_COLOR := Color("#7FAF99")
const CYAN_COLOR := Color("#78CEC1")
const GOLD_COLOR := Color("#E3C34F")
const DANGER_COLOR := Color("#D67A70")

func _ready() -> void:
	_build_ui()
	_start_battle()

func _style_box(color: Color, border_color: Color, radius: int = 12, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style

func _button_style(color: Color, border_color: Color, radius: int = 10, border_width: int = 1) -> StyleBoxFlat:
	var style := _style_box(color, border_color, radius, border_width)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style

func _make_panel(parent: Node, minimum_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _style_box(SURFACE_COLOR, BORDER_COLOR, 14, 1))
	parent.add_child(panel)
	return panel

func _make_label(text: String, font_size: int = 16, color: Color = TEXT_COLOR) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = BG_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 16)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_right", 16)
	root.add_theme_constant_override("margin_bottom", 10)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	root.add_child(layout)

	var header := _make_panel(layout, Vector2(0, 48))
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	header.add_child(header_row)

	var title := _make_label("GARLIA / BATALLA", 20, TEXT_COLOR)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	turn_label = _make_label("TURNO 1", 14, MUTED_COLOR)
	phase_label = _make_label("JUGADOR", 14, CYAN_COLOR)
	player_label = _make_label("VIDA 30", 14, TEXT_COLOR)
	enemy_label = _make_label("ENEMIGO 30", 14, TEXT_COLOR)
	etherium_label = _make_label("ETERIUM 3 / 3", 14, GOLD_COLOR)

	for label in [turn_label, phase_label, player_label, enemy_label, etherium_label]:
		header_row.add_child(label)

	var enemy_panel := _make_panel(layout, Vector2(0, 92))
	var enemy_content := VBoxContainer.new()
	enemy_content.add_theme_constant_override("separation", 8)
	enemy_panel.add_child(enemy_content)

	var enemy_title := _make_label("CAMPO ENEMIGO", 14, MUTED_COLOR)
	enemy_content.add_child(enemy_title)

	var enemy_row := HBoxContainer.new()
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_row.add_theme_constant_override("separation", 12)
	enemy_content.add_child(enemy_row)

	for i in range(BattleState.ENEMY_SLOTS):
		var slot := _make_panel(enemy_row, Vector2(196, 62))
		var label := _make_label("[ VACÍO ]", 16, MUTED_COLOR)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(label)
		enemy_slots.append(slot)

	var center_row := HBoxContainer.new()
	center_row.add_theme_constant_override("separation", 12)
	center_row.custom_minimum_size.y = 20
	layout.add_child(center_row)

	var left_rule := ColorRect.new()
	left_rule.color = BORDER_COLOR
	left_rule.custom_minimum_size = Vector2(0, 1)
	left_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_row.add_child(left_rule)

	var center_label := _make_label("VS", 18, GOLD_COLOR)
	center_label.custom_minimum_size.x = 46
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_row.add_child(center_label)

	var right_rule := ColorRect.new()
	right_rule.color = BORDER_COLOR
	right_rule.custom_minimum_size = Vector2(0, 1)
	right_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_row.add_child(right_rule)

	var player_panel := _make_panel(layout, Vector2(0, 98))
	var player_content := VBoxContainer.new()
	player_content.add_theme_constant_override("separation", 8)
	player_panel.add_child(player_content)

	var player_title := _make_label("TU CAMPO", 14, MUTED_COLOR)
	player_content.add_child(player_title)

	var player_row := HBoxContainer.new()
	player_row.alignment = BoxContainer.ALIGNMENT_CENTER
	player_row.add_theme_constant_override("separation", 12)
	player_content.add_child(player_row)

	for i in range(BattleState.PLAYER_SLOTS):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(196, 70)
		slot.add_theme_font_size_override("font_size", 16)
		slot.add_theme_color_override("font_color", TEXT_COLOR)
		slot.add_theme_color_override("font_hover_color", TEXT_COLOR)
		slot.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, BORDER_COLOR))
		slot.add_theme_stylebox_override("hover", _button_style(Color("#174A38"), CYAN_COLOR, 10, 2))
		slot.add_theme_stylebox_override("pressed", _button_style(Color("#3D3818"), GOLD_COLOR, 10, 2))
		slot.add_theme_stylebox_override("focus", _button_style(Color("#174A38"), CYAN_COLOR, 10, 2))
		slot.pressed.connect(_on_slot_pressed.bind(i))
		player_row.add_child(slot)
		slot_buttons.append(slot)

	var hand_header := HBoxContainer.new()
	hand_header.add_theme_constant_override("separation", 12)
	layout.add_child(hand_header)

	var hand_title := _make_label("MANO", 14, MUTED_COLOR)
	hand_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_header.add_child(hand_title)

	status_label = _make_label("Selecciona una carta.", 14, CYAN_COLOR)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_header.add_child(status_label)

	var hand_panel := _make_panel(layout, Vector2(0, 112))
	var hand := HBoxContainer.new()
	hand.alignment = BoxContainer.ALIGNMENT_CENTER
	hand.add_theme_constant_override("separation", 7)
	hand_panel.add_child(hand)

	for i in range(8):
		var button := Button.new()
		button.custom_minimum_size = Vector2(126, 94)
		button.add_theme_font_size_override("font_size", 11)
		button.add_theme_color_override("font_color", TEXT_COLOR)
		button.add_theme_color_override("font_hover_color", TEXT_COLOR)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, BORDER_COLOR, 12))
		button.add_theme_stylebox_override("hover", _button_style(Color("#174A38"), CYAN_COLOR, 12, 2))
		button.add_theme_stylebox_override("pressed", _button_style(Color("#3D3818"), GOLD_COLOR, 12, 2))
		button.add_theme_stylebox_override("disabled", _button_style(Color("#0B251C"), Color("#193D30"), 12))
		button.pressed.connect(_on_hand_pressed.bind(i))
		hand.add_child(button)
		hand_buttons.append(button)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 16)
	action_row.custom_minimum_size = Vector2(0, 52)
	layout.add_child(action_row)

	status_label = _make_label("SELECCIONA UNA CARTA", 14, CYAN_COLOR)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.custom_minimum_size.x = 320
	action_row.add_child(status_label)

	end_turn_button = Button.new()
	end_turn_button.text = "TERMINAR TURNO"
	end_turn_button.custom_minimum_size = Vector2(200, 44)
	end_turn_button.add_theme_font_size_override("font_size", 16)
	end_turn_button.add_theme_color_override("font_color", Color("#182016"))
	end_turn_button.add_theme_color_override("font_hover_color", Color("#182016"))
	end_turn_button.add_theme_stylebox_override("normal", _button_style(GOLD_COLOR, Color("#F0D76A"), 12, 1))
	end_turn_button.add_theme_stylebox_override("hover", _button_style(Color("#F0D76A"), Color("#FFF0A0"), 12, 2))
	end_turn_button.add_theme_stylebox_override("pressed", _button_style(Color("#B79B35"), GOLD_COLOR, 12, 2))
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	action_row.add_child(end_turn_button)

func _start_battle() -> void:
	state = BattleState.new()
	state.reset()
	state.deck = CardCatalog.starter_deck()

	var enemies := CardCatalog.enemy_deck()
	for i in range(min(enemies.size(), BattleState.ENEMY_SLOTS)):
		state.enemy_board.append(enemies[i])

	for i in range(5):
		state.draw_card()

	state.state_changed.connect(_refresh)
	_refresh()

func _on_hand_pressed(index: int) -> void:
	if index >= state.hand.size():
		return
	selected_card = state.hand[index]
	status_label.text = "SELECCIONADA · %s" % selected_card.display_name
	_refresh()

func _on_slot_pressed(index: int) -> void:
	if selected_card == null:
		status_label.text = "Selecciona una carta de la mano."
		return

	if selected_card.is_unit():
		if state.play_card(selected_card, index):
			selected_card = null
		else:
			status_label.text = "No puedes jugar esa carta ahí."
	else:
		if state.play_card(selected_card):
			selected_card = null

	_refresh()

func _on_end_turn_pressed() -> void:
	if state.is_finished():
		return

	state.end_turn()

	if state.is_finished():
		status_label.text = "VICTORIA" if state.player_won() else "DERROTA"
		end_turn_button.disabled = true

	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		_on_end_turn_pressed()

func _refresh() -> void:
	if state == null:
		return

	turn_label.text = "TURNO %d" % state.turn
	player_label.text = "VIDA %d" % state.player_health
	enemy_label.text = "ENEMIGO %d" % state.enemy_health
	etherium_label.text = "ETERIUM %d / %d" % [state.player_etherium, state.player_max_etherium]

	for i in range(hand_buttons.size()):
		var button := hand_buttons[i]
		if i < state.hand.size():
			var card: CardDefinition = state.hand[i]
			button.text = "%s\n\n%s\nCosto %d\n\n%s" % [card.display_name, card.type_name(), card.cost, card.description]
			button.disabled = card.cost > state.player_etherium
		else:
			button.text = ""
			button.disabled = true

	for i in range(slot_buttons.size()):
		if i < state.player_board.size() and state.player_board[i] != null:
			var card: CardDefinition = state.player_board[i]
			slot_buttons[i].text = "%s\n\nATQ %d   ·   VIDA %d" % [card.display_name, card.attack, card.health]
		else:
			slot_buttons[i].text = "POSICIÓN %d\n\nVACÍA" % (i + 1)
