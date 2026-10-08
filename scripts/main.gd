extends Node

var state: BattleState
var selected_card: CardDefinition
var selected_unit_slot := -1
var hand_buttons: Array[Button] = []
var player_slot_buttons: Array[Button] = []
var enemy_slot_buttons: Array[Button] = []
var enemy_slot_labels: Array[Label] = []
var title_label: Label
var enemy_label: Label
var player_label: Label
var etherium_label: Label
var turn_label: Label
var actions_label: Label
var deck_count_label: Label
var hand_count_label: Label
var selected_label: Label
var result_label: Label
var source_label: Label
var end_turn_button: Button
var restart_button: Button
var menu_button: Button

const MENU_SCENE_PATH := "res://scenes/main_menu.tscn"

const BG_COLOR := Color("#071E16")
const SURFACE_COLOR := Color("#0F3024")
const SURFACE_ALT_COLOR := Color("#123B2D")
const BORDER_COLOR := Color("#2C6651")
const TEXT_COLOR := Color("#E0EEE5")
const MUTED_COLOR := Color("#7FAF99")
const CYAN_COLOR := Color("#78CEC1")
const GOLD_COLOR := Color("#E3C34F")
const DANGER_COLOR := Color("#D67A70")
const SELECTED_COLOR := Color("#205B49")

func _ready() -> void:
	_build_ui()
	_start_battle()

func _style_box(color: Color, border_color: Color, radius: int = 10, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style

func _button_style(color: Color, border_color: Color, radius: int = 8, border_width: int = 1) -> StyleBoxFlat:
	var style := _style_box(color, border_color, radius, border_width)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style

func _make_panel(parent: Node, minimum_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style_box(SURFACE_COLOR, BORDER_COLOR, 10, 1))
	parent.add_child(panel)
	return panel

func _make_label(text: String, font_size: int = 14, color: Color = TEXT_COLOR) -> Label:
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
	root.add_theme_constant_override("margin_left", 10)
	root.add_theme_constant_override("margin_top", 10)
	root.add_theme_constant_override("margin_right", 10)
	root.add_theme_constant_override("margin_bottom", 10)
	add_child(root)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	root.add_child(columns)

	# TABLERO
	var board_column := VBoxContainer.new()
	board_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_column.size_flags_stretch_ratio = 1.45
	board_column.add_theme_constant_override("separation", 6)
	columns.add_child(board_column)

	var header := _make_panel(board_column, Vector2(0, 44))
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	header.add_child(header_row)

	title_label = _make_label("ENEMIGO", 18, TEXT_COLOR)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_label)

	turn_label = _make_label("T1", 12, MUTED_COLOR)
	actions_label = _make_label("A3", 12, CYAN_COLOR)
	player_label = _make_label("30", 12, TEXT_COLOR)
	enemy_label = _make_label("30", 12, DANGER_COLOR)
	etherium_label = _make_label("E3/3", 12, GOLD_COLOR)

	for label in [turn_label, actions_label, player_label, enemy_label, etherium_label]:
		header_row.add_child(label)

	var enemy_field := _make_panel(board_column)
	enemy_field.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var enemy_grid := GridContainer.new()
	enemy_grid.columns = BattleState.GRID_COLUMNS
	enemy_grid.add_theme_constant_override("h_separation", 5)
	enemy_grid.add_theme_constant_override("v_separation", 5)
	enemy_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_field.add_child(enemy_grid)

	for i in range(BattleState.ENEMY_SLOTS):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(0, 58)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot.add_theme_font_size_override("font_size", 10)
		slot.add_theme_color_override("font_color", TEXT_COLOR)
		slot.add_theme_color_override("font_hover_color", TEXT_COLOR)
		slot.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, BORDER_COLOR))
		slot.add_theme_stylebox_override("hover", _button_style(Color("#174A38"), CYAN_COLOR, 8, 2))
		slot.add_theme_stylebox_override("pressed", _button_style(Color("#3D3818"), GOLD_COLOR, 8, 2))
		slot.pressed.connect(_on_enemy_slot_pressed.bind(i))
		enemy_grid.add_child(slot)
		enemy_slot_buttons.append(slot)

	var vs := _make_label("VS", 12, GOLD_COLOR)
	vs.custom_minimum_size = Vector2(0, 18)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_column.add_child(vs)

	var player_field := _make_panel(board_column)
	player_field.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var player_grid := GridContainer.new()
	player_grid.columns = BattleState.GRID_COLUMNS
	player_grid.add_theme_constant_override("h_separation", 5)
	player_grid.add_theme_constant_override("v_separation", 5)
	player_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_field.add_child(player_grid)

	for i in range(BattleState.PLAYER_SLOTS):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(0, 58)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot.add_theme_font_size_override("font_size", 10)
		slot.add_theme_color_override("font_color", TEXT_COLOR)
		slot.add_theme_color_override("font_hover_color", TEXT_COLOR)
		slot.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, BORDER_COLOR))
		slot.add_theme_stylebox_override("hover", _button_style(Color("#174A38"), CYAN_COLOR, 8, 2))
		slot.add_theme_stylebox_override("pressed", _button_style(Color("#3D3818"), GOLD_COLOR, 8, 2))
		slot.pressed.connect(_on_player_slot_pressed.bind(i))
		player_grid.add_child(slot)
		player_slot_buttons.append(slot)

	# CARTAS
	var cards_column := VBoxContainer.new()
	cards_column.custom_minimum_size.x = 245
	cards_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_column.size_flags_stretch_ratio = 0.9
	cards_column.add_theme_constant_override("separation", 6)
	columns.add_child(cards_column)

	var deck_panel := _make_panel(cards_column, Vector2(0, 120))
	var deck_content := VBoxContainer.new()
	deck_content.alignment = BoxContainer.ALIGNMENT_CENTER
	deck_panel.add_child(deck_content)

	var deck_card := PanelContainer.new()
	deck_card.custom_minimum_size = Vector2(92, 78)
	deck_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	deck_card.add_theme_stylebox_override("panel", _style_box(Color("#174A38"), CYAN_COLOR, 8, 2))
	deck_content.add_child(deck_card)

	var deck_mark := _make_label("MAZO", 14, TEXT_COLOR)
	deck_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_card.add_child(deck_mark)

	deck_count_label = _make_label("0", 12, MUTED_COLOR)
	deck_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_content.add_child(deck_count_label)

	var hand_panel := _make_panel(cards_column)
	hand_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hand_content := VBoxContainer.new()
	hand_content.add_theme_constant_override("separation", 5)
	hand_panel.add_child(hand_content)

	hand_count_label = _make_label("0 CARTAS", 12, MUTED_COLOR)
	hand_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hand_content.add_child(hand_count_label)

	var hand_scroll := ScrollContainer.new()
	hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_content.add_child(hand_scroll)

	var hand_list := VBoxContainer.new()
	hand_list.add_theme_constant_override("separation", 5)
	hand_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.add_child(hand_list)

	for i in range(8):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 10)
		button.add_theme_color_override("font_color", TEXT_COLOR)
		button.add_theme_color_override("font_hover_color", TEXT_COLOR)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, BORDER_COLOR))
		button.add_theme_stylebox_override("hover", _button_style(Color("#174A38"), CYAN_COLOR, 8, 2))
		button.add_theme_stylebox_override("pressed", _button_style(SELECTED_COLOR, GOLD_COLOR, 8, 2))
		button.add_theme_stylebox_override("disabled", _button_style(Color("#0B251C"), Color("#193D30"), 8))
		button.pressed.connect(_on_hand_pressed.bind(i))
		hand_list.add_child(button)
		hand_buttons.append(button)

	# INFORMACIÓN
	var info_column := VBoxContainer.new()
	info_column.custom_minimum_size.x = 210
	info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_column.size_flags_stretch_ratio = 0.7
	info_column.add_theme_constant_override("separation", 6)
	columns.add_child(info_column)

	var info_panel := _make_panel(info_column)
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var info_content := VBoxContainer.new()
	info_content.add_theme_constant_override("separation", 8)
	info_panel.add_child(info_content)

	source_label = _make_label(GarliaCanon.get_status_text(), 10, CYAN_COLOR)
	source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_content.add_child(source_label)

	var player_title := _make_label("JUGADOR", 11, MUTED_COLOR)
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_content.add_child(player_title)

	var life_value := _make_label("VIDA", 11, MUTED_COLOR)
	life_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_content.add_child(life_value)

	var player_value := _make_label("30", 28, TEXT_COLOR)
	player_value.name = "PlayerValue"
	player_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_content.add_child(player_value)

	var etherium_title := _make_label("ETERIUM", 11, GOLD_COLOR)
	etherium_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_content.add_child(etherium_title)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_content.add_child(spacer)

	selected_label = _make_label("", 11, CYAN_COLOR)
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_content.add_child(selected_label)

	result_label = _make_label("", 16, GOLD_COLOR)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_content.add_child(result_label)

	end_turn_button = Button.new()
	end_turn_button.text = "TERMINAR"
	end_turn_button.custom_minimum_size = Vector2(0, 44)
	end_turn_button.add_theme_font_size_override("font_size", 13)
	end_turn_button.add_theme_color_override("font_color", Color("#182016"))
	end_turn_button.add_theme_color_override("font_hover_color", Color("#182016"))
	end_turn_button.add_theme_stylebox_override("normal", _button_style(GOLD_COLOR, Color("#F0D76A"), 8, 1))
	end_turn_button.add_theme_stylebox_override("hover", _button_style(Color("#F0D76A"), Color("#FFF0A0"), 8, 2))
	end_turn_button.add_theme_stylebox_override("pressed", _button_style(Color("#B79B35"), GOLD_COLOR, 8, 2))
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	info_content.add_child(end_turn_button)

	restart_button = Button.new()
	restart_button.text = "NUEVA"
	restart_button.custom_minimum_size = Vector2(0, 34)
	restart_button.add_theme_font_size_override("font_size", 11)
	restart_button.pressed.connect(_start_battle)
	info_content.add_child(restart_button)

	menu_button = Button.new()
	menu_button.text = "MENÚ"
	menu_button.custom_minimum_size = Vector2(0, 34)
	menu_button.add_theme_font_size_override("font_size", 11)
	menu_button.pressed.connect(_return_to_menu)
	info_content.add_child(menu_button)

func _start_battle() -> void:
	selected_card = null
	selected_unit_slot = -1
	result_label.text = ""
	end_turn_button.disabled = false

	var player_deck := CardCatalog.starter_deck()
	var enemies := CardCatalog.enemy_deck()

	if GarliaCanon.has_canon_data():
		player_deck = CardCatalog.starter_deck_from_canon(GarliaCanon)
		enemies = CardCatalog.enemy_deck_from_canon(GarliaCanon)

	state = BattleState.new()
	state.setup(player_deck, enemies)

	if not enemies.is_empty():
		title_label.text = enemies[0].display_name
	else:
		title_label.text = "ENEMIGO"

	if not state.state_changed.is_connected(_refresh):
		state.state_changed.connect(_refresh)
	if not state.event_occurred.is_connected(_on_battle_event):
		state.event_occurred.connect(_on_battle_event)
	if not state.battle_finished.is_connected(_on_battle_finished):
		state.battle_finished.connect(_on_battle_finished)

	_refresh()

func _on_hand_pressed(index: int) -> void:
	if state == null or state.is_finished() or index >= state.hand.size():
		return

	selected_card = state.hand[index]
	selected_unit_slot = -1
	_refresh()

func _on_player_slot_pressed(index: int) -> void:
	if state == null or state.is_finished():
		return

	if selected_card != null:
		if selected_card.is_unit():
			if state.play_card(selected_card, index):
				selected_card = null
				selected_unit_slot = -1
		else:
			if state.play_card(selected_card, index, false):
				selected_card = null
				selected_unit_slot = -1
		_refresh()
		return

	if index < state.player_board.size() and state.player_board[index] != null:
		var unit: CardDefinition = state.player_board[index]
		if unit.can_attack():
			selected_unit_slot = index
			result_label.text = unit.display_name
		else:
			selected_unit_slot = -1
		_refresh()

func _on_enemy_slot_pressed(index: int) -> void:
	if state == null or state.is_finished():
		return

	if selected_unit_slot >= 0:
		if state.attack_unit(selected_unit_slot, index):
			selected_unit_slot = -1
			selected_card = null
		_refresh()
		return

	if selected_card != null and not selected_card.is_unit():
		if state.play_card(selected_card, index, true):
			selected_card = null
		_refresh()

func _on_end_turn_pressed() -> void:
	if state == null or state.is_finished():
		return

	selected_card = null
	selected_unit_slot = -1
	state.end_turn()
	_refresh()

func _on_battle_event(message: String) -> void:
	result_label.text = message
	await get_tree().create_timer(1.1).timeout
	if state != null and not state.is_finished() and result_label.text == message:
		result_label.text = ""

func _on_battle_finished(player_won: bool) -> void:
	result_label.text = "VICTORIA" if player_won else "DERROTA"
	end_turn_button.disabled = true

func _return_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE:
			_on_end_turn_pressed()
		elif event.physical_keycode == KEY_ESCAPE:
			_return_to_menu()

func _refresh() -> void:
	if state == null:
		return

	turn_label.text = "T%d" % state.turn
	actions_label.text = "A%d" % state.player_actions
	player_label.text = "%d" % state.player_health
	enemy_label.text = "%d" % state.enemy_health
	etherium_label.text = "E%d/%d" % [state.player_etherium, state.player_max_etherium]
	deck_count_label.text = "%d" % state.deck.size()
	hand_count_label.text = "%d CARTAS" % state.hand.size()
	source_label.text = GarliaCanon.get_status_text()

	for i in range(enemy_slot_buttons.size()):
		var button := enemy_slot_buttons[i]
		if i < state.enemy_board.size() and state.enemy_board[i] != null:
			var card: CardDefinition = state.enemy_board[i]
			button.text = "%s\\n%d · %d" % [card.display_name, card.attack, card.health]
			button.disabled = false
		else:
			button.text = ""
			button.disabled = false

	for i in range(hand_buttons.size()):
		var button := hand_buttons[i]
		if i < state.hand.size():
			var card: CardDefinition = state.hand[i]
			button.text = "%s\\n%s · %d E" % [card.display_name, card.type_name(), card.cost]
			button.disabled = state.finished or card.cost > state.player_etherium or state.player_actions <= 0
		else:
			button.text = ""
			button.disabled = true

	for i in range(player_slot_buttons.size()):
		var button := player_slot_buttons[i]
		if i < state.player_board.size() and state.player_board[i] != null:
			var card: CardDefinition = state.player_board[i]
			button.text = "%s\\n%d · %d" % [card.display_name, card.attack, card.health]
			button.disabled = false
			button.add_theme_stylebox_override(
				"normal",
				_button_style(SELECTED_COLOR if i == selected_unit_slot else SURFACE_ALT_COLOR, CYAN_COLOR if i == selected_unit_slot else BORDER_COLOR)
			)
		else:
			button.text = ""
			button.disabled = false
			button.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, BORDER_COLOR))

	if selected_card != null:
		selected_label.text = selected_card.display_name
	else:
		selected_label.text = ""

	if state.finished:
		end_turn_button.disabled = true
