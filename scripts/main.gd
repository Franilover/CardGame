extends Control

@onready var canon_repository: Node = get_node("/root/GarliaCanonRepository")

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
const NEUTRAL_COLOR := Color("#1C3329")
const HERO_COLOR := Color("#C99F4A")
const HERO_BG_COLOR := Color("#3A301C")

var engine: BattleEngine
var state: BattleState
var selected_card_index: int = -1
var selected_unit_slot: int = -1

var board_buttons: Array[Button] = []
var mixer_buttons: Array[Button] = []
var hand_buttons: Array[Button] = []
var hand_units_row: HBoxContainer
var hand_objects_row: HBoxContainer
var ium_bar_row: HBoxContainer
var ium_buttons: Array[Button] = []
var available_iums: Array[CardDefinition] = []
var selected_ium_index: int = -1

var drag_source_slot: int = -1
var drag_press_position: Vector2 = Vector2.ZERO
var drag_active: bool = false

var enemy_name_label: Label
var player_name_label: Label
var enemy_health_label: Label
var player_health_label: Label
var enemy_health_bar: ProgressBar
var player_health_bar: ProgressBar
var turn_label: Label
var actions_label: Label
var etherium_label: Label
var etherium_bar: ProgressBar
var mixer_result_label: Label
var status_label: Label
var process_button: Button
var end_turn_button: Button
var hero_attack_panel: HBoxContainer
var hero_attack_buttons: Array[Button] = []
var hero_attack_directions: Array[Vector2i] = []

func _ready() -> void:
	_build_ui()
	_start_battle()

func _style_box(background: Color, border: Color, radius: int = 8, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func _button_style(background: Color, border: Color, radius: int = 7, width: int = 1) -> StyleBoxFlat:
	var style := _style_box(background, border, radius, width)
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style

func _new_panel(minimum_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _style_box(SURFACE_COLOR, BORDER_COLOR, 9, 1))
	return panel

func _make_label(text: String, font_size: int = 13, color: Color = TEXT_COLOR) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = BG_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	margin.add_child(root)

	root.add_child(_build_header())
	root.add_child(_build_middle())
	root.add_child(_build_hand_bar())
	root.add_child(_build_bottom_bar())

func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 82
	header.add_theme_constant_override("separation", 8)

	var enemy_panel := _build_character_panel(false)
	var center_panel := _new_panel(Vector2(0, 82))
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center_panel.add_child(center)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	center.add_child(row)

	turn_label = _make_label("T1", 12, TEXT_COLOR)
	actions_label = _make_label("ACCIONES 2/2", 12, CYAN_COLOR)
	row.add_child(turn_label)
	row.add_child(actions_label)

	var player_panel := _build_character_panel(true)
	header.add_child(enemy_panel)
	header.add_child(center_panel)
	header.add_child(player_panel)

	return header

func _build_character_panel(player: bool) -> PanelContainer:
	var panel := _new_panel(Vector2(260, 82))
	panel.custom_minimum_size.x = 260

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var portrait := Button.new()
	portrait.custom_minimum_size = Vector2(70, 62)
	portrait.text = "J" if player else "E"
	portrait.add_theme_font_size_override("font_size", 18)
	portrait.add_theme_color_override("font_color", TEXT_COLOR)
	portrait.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, CYAN_COLOR if player else DANGER_COLOR, 8, 2))
	portrait.add_theme_stylebox_override("hover", _button_style(SELECTED_COLOR, GOLD_COLOR, 8, 2))
	content.add_child(portrait)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(info)

	var name_label := _make_label("JUGADOR" if player else "ENEMIGO", 14, CYAN_COLOR if player else DANGER_COLOR)
	info.add_child(name_label)

	var health_bar := ProgressBar.new()
	health_bar.custom_minimum_size.y = 16
	health_bar.max_value = 30
	health_bar.value = 30
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", _style_box(Color("#07150F"), BORDER_COLOR, 5, 1))
	health_bar.add_theme_stylebox_override("fill", _style_box(CYAN_COLOR if player else DANGER_COLOR, CYAN_COLOR if player else DANGER_COLOR, 5, 1))
	info.add_child(health_bar)

	var health_label := _make_label("30 / 30", 11, TEXT_COLOR)
	info.add_child(health_label)

	if player:
		player_name_label = name_label
		player_health_bar = health_bar
		player_health_label = health_label
	else:
		enemy_name_label = name_label
		enemy_health_bar = health_bar
		enemy_health_label = health_label

	return panel

func _build_middle() -> Control:
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 8)

	var board_panel := _new_panel()
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_stretch_ratio = 2.8
	middle.add_child(board_panel)

	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 7)
	board_margin.add_theme_constant_override("margin_right", 7)
	board_margin.add_theme_constant_override("margin_top", 7)
	board_margin.add_theme_constant_override("margin_bottom", 7)
	board_panel.add_child(board_margin)

	var board_root := VBoxContainer.new()
	board_root.add_theme_constant_override("separation", 4)
	board_margin.add_child(board_root)

	var grid := GridContainer.new()
	grid.columns = BattleBoard.COLUMNS
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	board_root.add_child(grid)

	for index in range(BattleBoard.CELL_COUNT):
		var cell := Button.new()
		cell.custom_minimum_size = Vector2(0, 46)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell.add_theme_font_size_override("font_size", 8)
		cell.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cell.gui_input.connect(_on_board_gui_input.bind(index))
		grid.add_child(cell)
		board_buttons.append(cell)

	var mixer_panel := _new_panel(Vector2(315, 0))
	mixer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mixer_panel.size_flags_stretch_ratio = 1.0
	middle.add_child(mixer_panel)

	var mixer_margin := MarginContainer.new()
	mixer_margin.add_theme_constant_override("margin_left", 9)
	mixer_margin.add_theme_constant_override("margin_right", 9)
	mixer_margin.add_theme_constant_override("margin_top", 9)
	mixer_margin.add_theme_constant_override("margin_bottom", 9)
	mixer_panel.add_child(mixer_margin)

	var mixer_root := VBoxContainer.new()
	mixer_root.add_theme_constant_override("separation", 7)
	mixer_margin.add_child(mixer_root)

	var mixer_grid := GridContainer.new()
	mixer_grid.columns = 3
	mixer_grid.custom_minimum_size = Vector2(0, 165)
	mixer_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mixer_grid.add_theme_constant_override("h_separation", 4)
	mixer_grid.add_theme_constant_override("v_separation", 4)
	mixer_root.add_child(mixer_grid)

	for index in range(MixerState.SIZE):
		var cell := Button.new()
		cell.custom_minimum_size = Vector2(0, 51)
		cell.add_theme_font_size_override("font_size", 10)
		cell.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cell.text = "+"
		cell.pressed.connect(_on_mixer_pressed.bind(index))
		mixer_grid.add_child(cell)
		mixer_buttons.append(cell)

	etherium_bar = ProgressBar.new()
	etherium_bar.custom_minimum_size.y = 20
	etherium_bar.max_value = BattleState.MAX_ETHERIUM
	etherium_bar.value = 3
	etherium_bar.show_percentage = false
	etherium_bar.add_theme_stylebox_override("background", _style_box(Color("#151308"), BORDER_COLOR, 6, 1))
	etherium_bar.add_theme_stylebox_override("fill", _style_box(GOLD_COLOR, GOLD_COLOR, 6, 1))
	mixer_root.add_child(etherium_bar)

	etherium_label = _make_label("3 / 3", 12, GOLD_COLOR)
	etherium_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mixer_root.add_child(etherium_label)

	mixer_result_label = _make_label("", 10, MUTED_COLOR)
	mixer_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mixer_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mixer_root.add_child(mixer_result_label)

	process_button = Button.new()
	process_button.text = "PROCESAR"
	process_button.custom_minimum_size.y = 34
	process_button.add_theme_font_size_override("font_size", 11)
	process_button.add_theme_stylebox_override("normal", _button_style(GOLD_COLOR, Color("#F0D76A"), 7, 1))
	process_button.add_theme_color_override("font_color", Color("#182016"))
	process_button.pressed.connect(_on_process_pressed)
	mixer_root.add_child(process_button)

	var ium_scroll := ScrollContainer.new()
	ium_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	ium_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ium_scroll.custom_minimum_size.y = 62
	ium_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mixer_root.add_child(ium_scroll)

	ium_bar_row = HBoxContainer.new()
	ium_bar_row.add_theme_constant_override("separation", 5)
	ium_scroll.add_child(ium_bar_row)

	status_label = _make_label("", 10, CYAN_COLOR)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mixer_root.add_child(status_label)

	return middle

func _build_hand_bar() -> Control:
	var panel := _new_panel(Vector2(0, 115))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var groups := HBoxContainer.new()
	groups.size_flags_vertical = Control.SIZE_EXPAND_FILL
	groups.add_theme_constant_override("separation", 7)
	margin.add_child(groups)

	var units_section := VBoxContainer.new()
	units_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	units_section.size_flags_stretch_ratio = 3.0
	units_section.add_theme_constant_override("separation", 3)
	groups.add_child(units_section)

	var units_scroll := ScrollContainer.new()
	units_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	units_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	units_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	units_section.add_child(units_scroll)

	hand_units_row = HBoxContainer.new()
	hand_units_row.add_theme_constant_override("separation", 5)
	units_scroll.add_child(hand_units_row)

	var divider := VSeparator.new()
	divider.custom_minimum_size.x = 1
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	groups.add_child(divider)

	var objects_section := VBoxContainer.new()
	objects_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objects_section.size_flags_stretch_ratio = 1.0
	objects_section.add_theme_constant_override("separation", 3)
	groups.add_child(objects_section)

	var objects_scroll := ScrollContainer.new()
	objects_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	objects_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	objects_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	objects_section.add_child(objects_scroll)

	hand_objects_row = HBoxContainer.new()
	hand_objects_row.add_theme_constant_override("separation", 5)
	objects_scroll.add_child(hand_objects_row)

	for index in range(BattleState.MAX_HAND):
		var button := Button.new()
		button.custom_minimum_size = Vector2(145, 73)
		button.add_theme_font_size_override("font_size", 10)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_hand_pressed.bind(index))
		button.visible = false
		hand_buttons.append(button)

	return panel

func _build_bottom_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size.y = 42
	bar.add_theme_constant_override("separation", 7)

	hero_attack_panel = HBoxContainer.new()
	hero_attack_panel.add_theme_constant_override("separation", 3)
	hero_attack_panel.visible = false

	var directions: Array[Dictionary] = [
		{"label": "ARRIBA", "direction": Vector2i.UP},
		{"label": "ABAJO", "direction": Vector2i.DOWN},
		{"label": "IZQ", "direction": Vector2i.LEFT},
		{"label": "DER", "direction": Vector2i.RIGHT}
	]
	for direction_data in directions:
		var attack_button := Button.new()
		attack_button.text = str(direction_data["label"])
		attack_button.custom_minimum_size = Vector2(48, 34)
		attack_button.add_theme_font_size_override("font_size", 8)
		attack_button.pressed.connect(_on_hero_attack_pressed.bind(direction_data["direction"]))
		hero_attack_panel.add_child(attack_button)
		hero_attack_buttons.append(attack_button)
		hero_attack_directions.append(direction_data["direction"])

	bar.add_child(hero_attack_panel)

	end_turn_button = Button.new()
	end_turn_button.text = "TERMINAR TURNO"
	end_turn_button.custom_minimum_size = Vector2(150, 38)
	end_turn_button.add_theme_font_size_override("font_size", 11)
	end_turn_button.add_theme_stylebox_override("normal", _button_style(GOLD_COLOR, Color("#F0D76A"), 7, 1))
	end_turn_button.add_theme_color_override("font_color", Color("#182016"))
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	bar.add_child(end_turn_button)

	var back_button := Button.new()
	back_button.text = "RETROCEDER"
	back_button.custom_minimum_size = Vector2(120, 38)
	back_button.add_theme_font_size_override("font_size", 11)
	back_button.pressed.connect(_return_to_menu)
	bar.add_child(back_button)

	return bar

func _start_battle() -> void:
	selected_card_index = -1
	selected_unit_slot = -1
	selected_ium_index = -1
	status_label.text = ""

	var player_deck: Array[CardDefinition] = CardCatalog.starter_deck()
	var enemy_deck: Array[CardDefinition] = CardCatalog.enemy_deck()
	var process_catalog: Array[CardDefinition] = []
	available_iums.clear()

	var all_cards: Array[CardDefinition] = []
	if canon_repository.has_canon_data():
		all_cards = CardCatalog.from_canon(canon_repository)
		player_deck = CardCatalog.starter_deck_from_canon(canon_repository)
		enemy_deck = CardCatalog.enemy_deck_from_canon(canon_repository)

	for card in all_cards:
		if card.card_type == CardDefinition.CardType.IUM:
			available_iums.append(card)
		elif card.card_type == CardDefinition.CardType.PROCESS:
			process_catalog.append(card)

	if available_iums.is_empty():
		available_iums = CardCatalog.starter_ium_catalog()

	engine = BattleEngine.new()
	engine.setup(player_deck, enemy_deck, process_catalog, available_iums)
	state = engine.get_state()

	engine.state_changed.connect(_refresh)
	engine.event_emitted.connect(_on_engine_event)
	engine.command_resolved.connect(_on_command_resolved)
	engine.battle_finished.connect(_on_battle_finished)

	player_name_label.text = state.player_hero.display_name
	enemy_name_label.text = state.enemy_hero.display_name
	_populate_ium_bar()
	_refresh()

func _character_name_from_canon(fallback: String) -> String:
	var rows: Array = canon_repository.get_table("personajes_game")
	if not rows.is_empty() and rows[0] is Dictionary:
		var raw: Variant = rows[0].get("nombre", null)
		if raw != null:
			var name: String = str(raw).strip_edges()
			if not name.is_empty():
				return name
	return fallback

func _on_hand_pressed(index: int) -> void:
	if state == null or state.is_finished() or index < 0 or index >= state.hand.size():
		return
	selected_card_index = index
	selected_unit_slot = -1
	status_label.text = state.hand[index].display_name
	_refresh()

func _on_board_gui_input(event: InputEvent, index: int) -> void:
	if state == null or state.is_finished():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_source_slot = index if _is_draggable_player_unit(index) else -1
			drag_press_position = event.global_position
			drag_active = false
			return

		if drag_source_slot >= 0:
			var was_dragging: bool = drag_active
			var source: int = drag_source_slot
			drag_source_slot = -1
			drag_active = false
			if was_dragging:
				_resolve_board_drag(source, index)
				get_viewport().set_input_as_handled()
				return

		_on_board_pressed(index)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		if drag_source_slot >= 0 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			if event.global_position.distance_to(drag_press_position) >= 8.0:
				drag_active = true
				selected_unit_slot = drag_source_slot
				status_label.text = "Arrastrando %s · movimiento gratuito · una vez por turno." % state.board.get_card(drag_source_slot).display_name
				_refresh()
				get_viewport().set_input_as_handled()

func _is_draggable_player_unit(index: int) -> bool:
	if index < 0 or state == null:
		return false
	if state.board.get_owner(index) != BattleBoard.Owner.PLAYER:
		return false
	var unit: CardDefinition = state.board.get_card(index)
	return unit != null and unit.is_unit()

func _resolve_board_drag(source_slot: int, target_slot: int) -> void:
	if source_slot < 0 or target_slot < 0 or source_slot == target_slot:
		selected_unit_slot = source_slot if source_slot >= 0 else -1
		_refresh()
		return

	if source_slot == state.player_hero_slot and state.board.get_owner(target_slot) == BattleBoard.Owner.ENEMY:
		status_label.text = "Selecciona ARRIBA, ABAJO, IZQ o DER para elegir el lado del ataque del Rey."
		_refresh()
		return

	var result: BattleResult
	if state.board.get_owner(target_slot) == BattleBoard.Owner.ENEMY:
		result = engine.execute(BattleCommand.attack(source_slot, target_slot))
	elif state.board.is_empty(target_slot):
		result = engine.execute(BattleCommand.move_unit(source_slot, target_slot))
	else:
		status_label.text = "El destino está ocupado."
		_refresh()
		return

	if result.success:
		selected_unit_slot = -1
	else:
		status_label.text = "ERROR · %s" % result.message
		_refresh()

func _on_board_pressed(index: int) -> void:
	if state == null or state.is_finished():
		return

	if selected_card_index >= 0 and selected_card_index < state.hand.size():
		var card: CardDefinition = state.hand[selected_card_index]
		if card.card_type == CardDefinition.CardType.IUM:
					return
		var enemy_target: bool = state.board.get_owner(index) == BattleBoard.Owner.ENEMY
		var result: BattleResult = engine.execute(BattleCommand.play_card(selected_card_index, index, enemy_target))
		if result.success:
			selected_card_index = -1
		return

	if selected_unit_slot >= 0:
		if selected_unit_slot == state.player_hero_slot and state.board.get_owner(index) == BattleBoard.Owner.ENEMY:
			_refresh()
			return
		var result: BattleResult
		if state.board.get_owner(index) == BattleBoard.Owner.ENEMY:
			result = engine.execute(BattleCommand.attack(selected_unit_slot, index))
		elif state.board.is_empty(index):
			result = engine.execute(BattleCommand.move_unit(selected_unit_slot, index))
		else:
			status_label.text = "El destino está ocupado."
			return
		if result.success:
			selected_unit_slot = -1
		return

	if _is_draggable_player_unit(index):
		selected_unit_slot = index
		var selected_card: CardDefinition = state.board.get_card(index)
		status_label.text = "%s" % selected_card.display_name
		_refresh()

func _on_hero_attack_pressed(direction: Vector2i) -> void:
	if state == null or state.is_finished() or selected_unit_slot != state.player_hero_slot:
		return
	var result: BattleResult = engine.execute(BattleCommand.hero_attack(state.player_hero_slot, direction))
	if result.success:
		selected_unit_slot = -1
	else:
		status_label.text = "ERROR · %s" % result.message
	_refresh()

func _populate_ium_bar() -> void:
	for child in ium_bar_row.get_children():
		ium_bar_row.remove_child(child)
		child.queue_free()
	ium_buttons.clear()

	for index in range(available_iums.size()):
		var card: CardDefinition = available_iums[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(104, 48)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.add_theme_font_size_override("font_size", 10)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = card.display_name
		button.tooltip_text = card.description
		button.pressed.connect(_on_ium_catalog_pressed.bind(index))
		button.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, BORDER_COLOR, 7, 1))
		button.add_theme_stylebox_override("hover", _button_style(SELECTED_COLOR, GOLD_COLOR, 7, 1))
		ium_bar_row.add_child(button)
		ium_buttons.append(button)

func _on_ium_catalog_pressed(index: int) -> void:
	if state == null or state.is_finished():
		return
	if index < 0 or index >= available_iums.size():
		return

	if selected_ium_index == index:
		selected_ium_index = -1
		status_label.text = ""
	else:
		selected_ium_index = index
		status_label.text = "%s seleccionado. Elige una casilla vacía del mezclador." % available_iums[index].display_name

	_refresh()

func _on_mixer_pressed(index: int) -> void:
	if state == null or state.is_finished():
		return

	if selected_ium_index >= 0:
		if not state.mixer.is_empty(index):
			status_label.text = "Selecciona una casilla vacía del mezclador."
			_refresh()
			return
		var place_result: BattleResult = engine.execute(
			BattleCommand.mixer_catalog_place(selected_ium_index, index)
		)
		if place_result.success:
			selected_ium_index = -1
			_refresh()
		return

	if selected_card_index >= 0 and selected_card_index < state.hand.size():
		var card: CardDefinition = state.hand[selected_card_index]
		if card != null and card.card_type == CardDefinition.CardType.IUM:
			var result: BattleResult = engine.execute(BattleCommand.mixer_place(selected_card_index, index))
			if result.success:
				selected_card_index = -1
			return

	if not state.mixer.is_empty(index):
		engine.execute(BattleCommand.mixer_remove(index))
		selected_ium_index = -1

func _on_process_pressed() -> void:
	if state == null or state.is_finished():
		return
	engine.execute(BattleCommand.mixer_resolve())

func _on_end_turn_pressed() -> void:
	if state == null or state.is_finished():
		return
	selected_card_index = -1
	selected_unit_slot = -1
	engine.execute(BattleCommand.end_turn())

func _on_command_resolved(result: BattleResult) -> void:
	status_label.text = result.message
	if not result.success:
		status_label.text = "ERROR · %s" % result.message
	_refresh()

func _on_engine_event(event: BattleEvent) -> void:
	if event.type == BattleEvent.EventType.DIAGNOSTIC:
		status_label.text = event.message

func _on_battle_finished(player_won: bool) -> void:
	status_label.text = "VICTORIA" if player_won else "DERROTA"
	end_turn_button.disabled = true
	process_button.disabled = true
	_refresh()

func _refresh() -> void:
	if state == null:
		return

	turn_label.text = "T%d" % state.turn
	actions_label.text = "ACCIONES %d/%d" % [state.player_actions, state.player_max_actions]
	player_health_label.text = "%d / %d" % [state.player_hero.health, BattleState.HERO_MAX_HEALTH]
	enemy_health_label.text = "%d / %d" % [state.enemy_hero.health, BattleState.HERO_MAX_HEALTH]
	player_health_bar.value = state.player_hero.health
	enemy_health_bar.value = state.enemy_hero.health
	etherium_bar.value = state.player_etherium
	etherium_label.text = "%d / %d" % [state.player_etherium, state.player_max_etherium]

	var recipe: CardDefinition = MixerEngine.find_process(state.mixer, state.process_catalog)
	if state.mixer.count() == 0:
		mixer_result_label.text = ""
		process_button.disabled = true
	elif recipe != null:
		mixer_result_label.text = recipe.display_name
		process_button.disabled = state.player_actions <= 0 or state.player_etherium <= 0 or state.hand.size() >= BattleState.MAX_HAND
	else:
		mixer_result_label.text = ""
		process_button.disabled = true

	for index in range(board_buttons.size()):
		var button: Button = board_buttons[index]
		var occupant: CardDefinition = state.board.get_card(index)
		var owner: int = state.board.get_owner(index)
		var selected: bool = index == selected_unit_slot
		if occupant != null:
			if index == state.player_hero_slot:
				button.text = "REY\n%s\n%d V" % [occupant.display_name, occupant.health]
			elif index == state.enemy_hero_slot:
				button.text = "REINA\n%s\n%d V" % [occupant.display_name, occupant.health]
			else:
				var mark: String = "E" if owner == BattleBoard.Owner.ENEMY else "J"
				button.text = "%s\n%s\n%d ATQ · %d V" % [mark, occupant.display_name, occupant.attack, occupant.health]
		else:
			button.text = ""
		button.add_theme_stylebox_override("normal", _cell_style(index, selected))
		button.add_theme_stylebox_override("hover", _cell_style(index, true))

	for index in range(mixer_buttons.size()):
		var mixer_button: Button = mixer_buttons[index]
		var mixer_card: CardDefinition = state.mixer.get_ium(index)
		mixer_button.text = mixer_card.display_name if mixer_card != null else "+"
		mixer_button.add_theme_stylebox_override("normal", _button_style(SELECTED_COLOR if mixer_card != null else SURFACE_ALT_COLOR, GOLD_COLOR if mixer_card != null else BORDER_COLOR, 7, 1))

	for hand_button in hand_buttons:
		if hand_button.get_parent() != null:
			hand_button.get_parent().remove_child(hand_button)
		hand_button.visible = false

	for index in range(hand_buttons.size()):
		var hand_button: Button = hand_buttons[index]
		if index >= state.hand.size():
			continue

		var card: CardDefinition = state.hand[index]
		var target_row: HBoxContainer = null

		match card.card_type:
			CardDefinition.CardType.CREATURE:
				target_row = hand_units_row
			CardDefinition.CardType.CHARACTER:
				target_row = hand_units_row
			CardDefinition.CardType.OBJECT:
				target_row = hand_objects_row
			CardDefinition.CardType.IUM:
				continue
			CardDefinition.CardType.PROCESS:
				continue
			CardDefinition.CardType.ORIS:
				continue

		if target_row == null:
			continue

		target_row.add_child(hand_button)
		hand_button.visible = true

		hand_button.text = card.display_name
		hand_button.tooltip_text = card.description
		hand_button.disabled = (
			state.finished
			or etherium_cost > state.player_etherium
			or state.player_actions <= 0
		)
		hand_button.add_theme_stylebox_override(
			"normal",
			_button_style(
				SELECTED_COLOR if index == selected_card_index else SURFACE_ALT_COLOR,
				GOLD_COLOR if index == selected_card_index else BORDER_COLOR,
				7,
				2 if index == selected_card_index else 1
			)
		)

	for index in range(ium_buttons.size()):
		var ium_button: Button = ium_buttons[index]
		ium_button.disabled = state.finished
		ium_button.add_theme_stylebox_override(
			"normal",
			_button_style(
				SELECTED_COLOR if index == selected_ium_index else SURFACE_ALT_COLOR,
				GOLD_COLOR if index == selected_ium_index else BORDER_COLOR,
				7,
				2 if index == selected_ium_index else 1
			)
		)

	end_turn_button.disabled = state.finished
	hero_attack_panel.visible = state.player_hero != null and selected_unit_slot == state.player_hero_slot and not state.finished
	for direction_index in range(hero_attack_buttons.size()):
		var direction: Vector2i = hero_attack_directions[direction_index]
		var valid_three_cell_attack: bool = state.board.front_attack_indices(state.player_hero_slot, direction).size() == 3
		hero_attack_buttons[direction_index].disabled = state.finished or state.player_actions <= 0 or not state.player_hero.can_attack() or not valid_three_cell_attack

func _cell_style(index: int, selected: bool) -> StyleBoxFlat:
	var background := SURFACE_ALT_COLOR
	var border := BORDER_COLOR
	var width := 1
	if state != null:
		if state.board.is_hero_slot(index):
			background = HERO_BG_COLOR
			border = HERO_COLOR
			width = 2
		elif state.board.is_enemy_zone(index):
			background = Color("#2C2024")
		elif state.board.is_player_zone(index):
			background = Color("#15352A")
		else:
			background = NEUTRAL_COLOR
	if selected:
		background = SELECTED_COLOR
		border = GOLD_COLOR
		width = 2
	return _button_style(background, border, 5, width)

func _return_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_return_to_menu()
		elif event.physical_keycode == KEY_SPACE:
			_on_end_turn_pressed()
