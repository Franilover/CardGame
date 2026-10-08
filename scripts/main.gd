extends Node

var state: BattleState
var selected_card: CardDefinition
var hand_buttons: Array[Button] = []
var player_slot_buttons: Array[Button] = []
var enemy_slot_panels: Array[PanelContainer] = []
var enemy_slot_labels: Array[Label] = []
var player_slot_buttons_by_index: Array[Button] = []
var enemy_label: Label
var player_label: Label
var etherium_label: Label
var turn_label: Label
var deck_count_label: Label
var hand_count_label: Label
var title_label: Label
var end_turn_button: Button
var result_label: Label

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
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

func _make_panel(parent: Node, minimum_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	root.add_theme_constant_override("margin_left", 14)
	root.add_theme_constant_override("margin_top", 12)
	root.add_theme_constant_override("margin_right", 14)
	root.add_theme_constant_override("margin_bottom", 12)
	add_child(root)

	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 12)
	root.add_child(main_row)

	var battlefield := VBoxContainer.new()
	battlefield.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield.size_flags_stretch_ratio = 3.6
	battlefield.add_theme_constant_override("separation", 7)
	main_row.add_child(battlefield)

	var header := _make_panel(battlefield, Vector2(0, 48))
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	header.add_child(header_row)

	title_label = _make_label("ENEMIGO", 20, TEXT_COLOR)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_label)

	turn_label = _make_label("TURNO 1", 13, MUTED_COLOR)
	player_label = _make_label("VIDA 30", 13, TEXT_COLOR)
	enemy_label = _make_label("30", 13, DANGER_COLOR)
	etherium_label = _make_label("ETERIUM 3 / 3", 13, GOLD_COLOR)

	for label in [turn_label, player_label, enemy_label, etherium_label]:
		header_row.add_child(label)

	var enemy_field := _make_panel(battlefield, Vector2(0, 270))
	var enemy_grid := GridContainer.new()
	enemy_grid.columns = BattleState.GRID_COLUMNS
	enemy_grid.add_theme_constant_override("h_separation", 8)
	enemy_grid.add_theme_constant_override("v_separation", 8)
	enemy_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_field.add_child(enemy_grid)

	for i in range(BattleState.ENEMY_SLOTS):
		var slot := _make_panel(enemy_grid, Vector2(0, 74))
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_stretch_ratio = 1.0
		var label := _make_label("", 12, MUTED_COLOR)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_child(label)
		enemy_slot_panels.append(slot)
		enemy_slot_labels.append(label)

	var vs_row := HBoxContainer.new()
	vs_row.custom_minimum_size = Vector2(0, 18)
	vs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	battlefield.add_child(vs_row)

	var vs := _make_label("VS", 14, GOLD_COLOR)
	vs.custom_minimum_size.x = 40
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_row.add_child(vs)

	var player_field := _make_panel(battlefield, Vector2(0, 270))
	var player_grid := GridContainer.new()
	player_grid.columns = BattleState.GRID_COLUMNS
	player_grid.add_theme_constant_override("h_separation", 8)
	player_grid.add_theme_constant_override("v_separation", 8)
	player_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_field.add_child(player_grid)

	for i in range(BattleState.PLAYER_SLOTS):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(0, 74)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_stretch_ratio = 1.0
		slot.add_theme_font_size_override("font_size", 12)
		slot.add_theme_color_override("font_color", TEXT_COLOR)
		slot.add_theme_color_override("font_hover_color", TEXT_COLOR)
		slot.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, BORDER_COLOR))
		slot.add_theme_stylebox_override("hover", _button_style(Color("#174A38"), CYAN_COLOR, 10, 2))
		slot.add_theme_stylebox_override("pressed", _button_style(Color("#3D3818"), GOLD_COLOR, 10, 2))
		slot.add_theme_stylebox_override("focus", _button_style(Color("#174A38"), CYAN_COLOR, 10, 2))
		slot.pressed.connect(_on_slot_pressed.bind(i))
		player_grid.add_child(slot)
		player_slot_buttons.append(slot)

	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 270
	side.size_flags_horizontal = Control.SIZE_SHRINK_END
	side.add_theme_constant_override("separation", 8)
	main_row.add_child(side)

	var deck_panel := _make_panel(side, Vector2(0, 210))
	var deck_content := VBoxContainer.new()
	deck_content.add_theme_constant_override("separation", 8)
	deck_panel.add_child(deck_content)

	var deck_title := _make_label("MAZO", 13, MUTED_COLOR)
	deck_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_content.add_child(deck_title)

	var deck_card := PanelContainer.new()
	deck_card.custom_minimum_size = Vector2(150, 150)
	deck_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	deck_card.add_theme_stylebox_override("panel", _style_box(Color("#174A38"), CYAN_COLOR, 12, 2))
	deck_content.add_child(deck_card)

	var deck_mark := _make_label("GARLIA", 18, TEXT_COLOR)
	deck_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_card.add_child(deck_mark)

	deck_count_label = _make_label("0 CARTAS", 13, MUTED_COLOR)
	deck_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	deck_content.add_child(deck_count_label)

	var hand_panel := _make_panel(side, Vector2(0, 0))
	hand_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hand_content := VBoxContainer.new()
	hand_content.add_theme_constant_override("separation", 6)
	hand_panel.add_child(hand_content)

	hand_count_label = _make_label("CARTAS 0", 13, MUTED_COLOR)
	hand_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hand_content.add_child(hand_count_label)

	var hand_scroll := ScrollContainer.new()
	hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_content.add_child(hand_scroll)

	var hand_list := VBoxContainer.new()
	hand_list.add_theme_constant_override("separation", 6)
	hand_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.add_child(hand_list)

	for i in range(8):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 72)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 11)
		button.add_theme_color_override("font_color", TEXT_COLOR)
		button.add_theme_color_override("font_hover_color", TEXT_COLOR)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, BORDER_COLOR, 10))
		button.add_theme_stylebox_override("hover", _button_style(Color("#174A38"), CYAN_COLOR, 10, 2))
		button.add_theme_stylebox_override("pressed", _button_style(Color("#3D3818"), GOLD_COLOR, 10, 2))
		button.add_theme_stylebox_override("disabled", _button_style(Color("#0B251C"), Color("#193D30"), 10))
		button.pressed.connect(_on_hand_pressed.bind(i))
		hand_list.add_child(button)
		hand_buttons.append(button)

	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size = Vector2(0, 50)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 10)
	side.add_child(bottom)

	result_label = _make_label("", 12, CYAN_COLOR)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.custom_minimum_size.x = 50
	bottom.add_child(result_label)

	end_turn_button = Button.new()
	end_turn_button.text = "TERMINAR TURNO"
	end_turn_button.custom_minimum_size = Vector2(190, 44)
	end_turn_button.add_theme_font_size_override("font_size", 14)
	end_turn_button.add_theme_color_override("font_color", Color("#182016"))
	end_turn_button.add_theme_color_override("font_hover_color", Color("#182016"))
	end_turn_button.add_theme_stylebox_override("normal", _button_style(GOLD_COLOR, Color("#F0D76A"), 10, 1))
	end_turn_button.add_theme_stylebox_override("hover", _button_style(Color("#F0D76A"), Color("#FFF0A0"), 10, 2))
	end_turn_button.add_theme_stylebox_override("pressed", _button_style(Color("#B79B35"), GOLD_COLOR, 10, 2))
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	bottom.add_child(end_turn_button)

func _start_battle() -> void:
	state = BattleState.new()
	state.reset()
	state.deck = CardCatalog.starter_deck()

	var enemies := CardCatalog.enemy_deck()
	for i in range(min(enemies.size(), BattleState.ENEMY_SLOTS)):
		state.enemy_board[i] = enemies[i]

	for i in range(5):
		state.draw_card()

	if not enemies.is_empty():
		title_label.text = enemies[0].display_name
	else:
		title_label.text = "ENEMIGO"

	state.state_changed.connect(_refresh)
	_refresh()

func _on_hand_pressed(index: int) -> void:
	if index >= state.hand.size():
		return
	selected_card = state.hand[index]
	_refresh()

func _on_slot_pressed(index: int) -> void:
	if selected_card == null:
		return

	if selected_card.is_unit():
		if state.play_card(selected_card, index):
			selected_card = null
	else:
		if state.play_card(selected_card):
			selected_card = null

	_refresh()

func _on_end_turn_pressed() -> void:
	if state.is_finished():
		return

	state.end_turn()

	if state.is_finished():
		result_label.text = "VICTORIA" if state.player_won() else "DERROTA"
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
	enemy_label.text = "%d" % state.enemy_health
	etherium_label.text = "ETERIUM %d / %d" % [state.player_etherium, state.player_max_etherium]
	deck_count_label.text = "%d CARTAS" % state.deck.size()
	hand_count_label.text = "CARTAS %d" % state.hand.size()

	for i in range(enemy_slot_labels.size()):
		if i < state.enemy_board.size() and state.enemy_board[i] != null:
			var card: CardDefinition = state.enemy_board[i]
			enemy_slot_labels[i].text = "%s\\nATQ %d · VIDA %d" % [card.display_name, card.attack, card.health]
		else:
			enemy_slot_labels[i].text = ""

	for i in range(hand_buttons.size()):
		var button := hand_buttons[i]
		if i < state.hand.size():
			var card: CardDefinition = state.hand[i]
			button.text = "%s  ·  %s  ·  %d E\\n%s" % [card.display_name, card.type_name(), card.cost, card.description]
			button.disabled = card.cost > state.player_etherium
		else:
			button.text = ""
			button.disabled = true

	for i in range(player_slot_buttons.size()):
		if i < state.player_board.size() and state.player_board[i] != null:
			var card: CardDefinition = state.player_board[i]
			player_slot_buttons[i].text = "%s\\nATQ %d · VIDA %d" % [card.display_name, card.attack, card.health]
		else:
			player_slot_buttons[i].text = ""

	if selected_card != null:
		result_label.text = selected_card.display_name
	else:
		result_label.text = ""
