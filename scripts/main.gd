extends Control

@onready var canon_repository: Node = get_node("/root/GarliaCanonRepository")
@onready var run_progress: Node = get_node("/root/RunProgress")

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
const TEAM_TINT_SHADER: Shader = preload("res://assets/shaders/team_tint.gdshader")

var engine: BattleEngine
var state: BattleState
var selected_card_index: int = -1
var selected_unit_slot: int = -1
var attack_preview_slot: int = -1
var movement_preview_slot: int = -1
var ignore_next_board_release: bool = false

var board_buttons: Array[Button] = []
var board_piece_sprites: Array[TextureRect] = []
var board_health_bars: Array[ProgressBar] = []
var mixer_buttons: Array[Button] = []
var hand_buttons: Array[Button] = []
var hand_units_row: HBoxContainer
var hand_objects_row: HBoxContainer
var loadout_inventory_row: HBoxContainer
var ium_bar_row: HBoxContainer
var ium_buttons: Array[Button] = []
var available_iums: Array[CardDefinition] = []
var catalog_cards: Array[CardDefinition] = []
var current_encounter_label: String = ""
var selected_ium_index: int = -1

var drag_source_slot: int = -1
var drag_press_position: Vector2 = Vector2.ZERO
var drag_active: bool = false

var enemy_name_label: Label
var player_name_label: Label
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
var pixel_sprite_cache: Dictionary = {}
var creature_sprite_paths: Dictionary = {}
var middle_container: Control
var board_grid: GridContainer

func _ready() -> void:
	_scan_creature_sprites()
	_build_ui()
	_start_battle()
	call_deferred("_fit_board_cells")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		call_deferred("_fit_board_cells")

func _style_box(background: Color, border: Color, radius: int = 0, width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(0)
	return style

func _button_style(background: Color, border: Color, radius: int = 0, width: int = 2) -> StyleBoxFlat:
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

	root.add_child(_build_middle())
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

func _build_side_status() -> PanelContainer:
	var panel := _new_panel(Vector2(315, 94))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	panel.add_child(content)

	var heroes_row := HBoxContainer.new()
	heroes_row.add_theme_constant_override("separation", 8)
	content.add_child(heroes_row)

	enemy_name_label = _make_label("REY ENEMIGO", 11, DANGER_COLOR)
	enemy_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heroes_row.add_child(enemy_name_label)

	player_name_label = _make_label("TU REY", 11, CYAN_COLOR)
	player_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heroes_row.add_child(player_name_label)

	var turn_row := HBoxContainer.new()
	turn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	turn_row.add_theme_constant_override("separation", 12)
	content.add_child(turn_row)
	turn_label = _make_label("T0", 10, TEXT_COLOR)
	actions_label = _make_label("DESPLIEGUE GRATUITO", 10, CYAN_COLOR)
	turn_row.add_child(turn_label)
	turn_row.add_child(actions_label)
	return panel

func _build_character_panel(player: bool) -> PanelContainer:
	var panel := _new_panel(Vector2(260, 82))
	panel.custom_minimum_size.x = 260

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var portrait := Button.new()
	portrait.custom_minimum_size = Vector2(64, 64)
	portrait.text = "J" if player else "E"
	portrait.add_theme_font_size_override("font_size", 18)
	portrait.add_theme_color_override("font_color", TEXT_COLOR)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, CYAN_COLOR if player else DANGER_COLOR, 0, 2))
	portrait.add_theme_stylebox_override("hover", _button_style(SELECTED_COLOR, GOLD_COLOR, 0, 2))
	content.add_child(portrait)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(info)

	var name_label := _make_label("TU REY" if player else "REY ENEMIGO", 14, CYAN_COLOR if player else DANGER_COLOR)
	info.add_child(name_label)
	if player:
		player_name_label = name_label
	else:
		enemy_name_label = name_label

	return panel

func _build_middle() -> Control:
	var middle := HBoxContainer.new()
	middle_container = middle
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 8)

	var board_panel := _new_panel()
	board_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(board_panel)

	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 7)
	board_margin.add_theme_constant_override("margin_right", 7)
	board_margin.add_theme_constant_override("margin_top", 7)
	board_margin.add_theme_constant_override("margin_bottom", 7)
	board_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.add_child(board_margin)

	var board_root := VBoxContainer.new()
	board_root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	board_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_root.add_theme_constant_override("separation", 4)
	board_margin.add_child(board_root)

	var grid := GridContainer.new()
	board_grid = grid
	grid.columns = BattleBoard.COLUMNS
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	board_root.add_child(grid)

	for index in range(BattleBoard.CELL_COUNT):
		var cell := Button.new()
		var cell_size: float = 64.0
		cell.custom_minimum_size = Vector2(cell_size, cell_size)
		cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.clip_contents = true
		cell.autowrap_mode = TextServer.AUTOWRAP_OFF
		cell.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cell.add_theme_font_size_override("font_size", 7 if run_progress.mode == "exploration" else 8)
		cell.gui_input.connect(_on_board_gui_input.bind(index))
		var piece_sprite := TextureRect.new()
		piece_sprite.name = "PieceSprite"
		piece_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		piece_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		piece_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tint_material := ShaderMaterial.new()
		tint_material.shader = TEAM_TINT_SHADER
		piece_sprite.material = tint_material
		cell.add_child(piece_sprite)

		var health_bar := ProgressBar.new()
		health_bar.name = "HealthBar"
		health_bar.anchor_left = 0.0
		health_bar.anchor_right = 1.0
		health_bar.anchor_top = 1.0
		health_bar.anchor_bottom = 1.0
		health_bar.offset_left = 4.0
		health_bar.offset_right = -4.0
		health_bar.offset_top = -7.0
		health_bar.offset_bottom = -3.0
		health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		health_bar.show_percentage = false
		health_bar.min_value = 0.0
		health_bar.max_value = 1.0
		health_bar.value = 1.0
		health_bar.add_theme_stylebox_override("background", _style_box(Color("#101714"), Color("#101714"), 0, 0))
		health_bar.add_theme_stylebox_override("fill", _style_box(Color("#45E878"), Color("#45E878"), 0, 0))
		cell.add_child(health_bar)
		grid.add_child(cell)
		board_buttons.append(cell)
		board_piece_sprites.append(piece_sprite)
		board_health_bars.append(health_bar)

	var side_column := VBoxContainer.new()
	side_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_column.size_flags_stretch_ratio = 1.0
	side_column.add_theme_constant_override("separation", 7)
	middle.add_child(side_column)

	var battle_status_panel := _build_side_status()
	battle_status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_column.add_child(battle_status_panel)

	var mixer_panel := _new_panel(Vector2(315, 0))
	mixer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mixer_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mixer_panel.size_flags_stretch_ratio = 2.0
	side_column.add_child(mixer_panel)

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
	ium_scroll.visible = run_progress.mode == "bosses"
	mixer_root.add_child(ium_scroll)

	ium_bar_row = HBoxContainer.new()
	ium_bar_row.add_theme_constant_override("separation", 5)
	ium_scroll.add_child(ium_bar_row)

	status_label = _make_label("", 10, CYAN_COLOR)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mixer_root.add_child(status_label)

	var hand_panel := _build_hand_bar()
	hand_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hand_panel.size_flags_stretch_ratio = 1.0
	side_column.add_child(hand_panel)

	return middle


func _fit_board_cells() -> void:
	if middle_container == null or board_grid == null or board_buttons.is_empty():
		return
	if middle_container.size.y <= 0.0:
		return
	var height_limit: float = (middle_container.size.y - 22.0) / float(BattleBoard.ROWS)
	var width_limit: float = (size.x * 0.46) / float(BattleBoard.COLUMNS)
	var cell_size: float = clampf(floor(minf(height_limit, width_limit)), 24.0, 64.0)
	for cell in board_buttons:
		cell.custom_minimum_size = Vector2(cell_size, cell_size)
	board_grid.custom_minimum_size = Vector2(cell_size * BattleBoard.COLUMNS, cell_size * BattleBoard.ROWS)

func _build_hand_bar() -> Control:
	var panel := _new_panel(Vector2(0, 128))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	var inventory_root := VBoxContainer.new()
	inventory_root.add_theme_constant_override("separation", 4)
	margin.add_child(inventory_root)

	var loadout_header := _make_label("MAZO EQUIPADO", 9, MUTED_COLOR)
	inventory_root.add_child(loadout_header)

	var loadout_scroll := ScrollContainer.new()
	loadout_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	loadout_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	loadout_scroll.custom_minimum_size.y = 34
	loadout_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_root.add_child(loadout_scroll)

	loadout_inventory_row = HBoxContainer.new()
	loadout_inventory_row.add_theme_constant_override("separation", 4)
	loadout_scroll.add_child(loadout_inventory_row)

	var hand_header := _make_label("EN MANO", 9, MUTED_COLOR)
	inventory_root.add_child(hand_header)

	var groups := HBoxContainer.new()
	groups.size_flags_vertical = Control.SIZE_EXPAND_FILL
	groups.add_theme_constant_override("separation", 7)
	inventory_root.add_child(groups)

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
		button.custom_minimum_size = Vector2(120, 58)
		button.add_theme_font_size_override("font_size", 10)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_hand_pressed.bind(index))
		button.visible = false
		hand_buttons.append(button)

	return panel

func _populate_loadout_inventory() -> void:
	if loadout_inventory_row == null:
		return
	for child in loadout_inventory_row.get_children():
		loadout_inventory_row.remove_child(child)
		child.queue_free()
	var cards_by_id: Dictionary = {}
	for card in catalog_cards:
		if card != null and not cards_by_id.has(card.id):
			cards_by_id[card.id] = card
	for card_id in run_progress.loadout_ids:
		if card_id.is_empty():
			continue
		var card: CardDefinition = cards_by_id.get(card_id) as CardDefinition
		if card == null:
			continue
		var card_button := Button.new()
		card_button.custom_minimum_size = Vector2(88, 32)
		card_button.custom_minimum_size.x = 88
		card_button.text = card.display_name
		card_button.tooltip_text = "%s · ATQ %d · VIDA %d" % [card.display_name, card.attack, card.health]
		card_button.add_theme_font_size_override("font_size", 9)
		card_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_button.add_theme_stylebox_override("normal", _button_style(SURFACE_ALT_COLOR, BORDER_COLOR, 0, 1))
		card_button.add_theme_stylebox_override("hover", _button_style(SELECTED_COLOR, CYAN_COLOR, 0, 1))
		card_button.disabled = true
		loadout_inventory_row.add_child(card_button)

func _build_bottom_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size.y = 36
	bar.add_theme_constant_override("separation", 7)

	hero_attack_panel = HBoxContainer.new()
	hero_attack_panel.add_theme_constant_override("separation", 3)
	hero_attack_panel.visible = false

	var directions: Array[Dictionary] = []
	if run_progress.selected_character_style == "archer":
		directions = [
			{"label": "FLECHA ↑", "direction": Vector2i.UP},
			{"label": "FLECHA ↓", "direction": Vector2i.DOWN},
			{"label": "FLECHA ←", "direction": Vector2i.LEFT},
			{"label": "FLECHA →", "direction": Vector2i.RIGHT}
		]
	else:
		directions = [{"label": "GOLPE CIRCULAR", "direction": Vector2i.ZERO}]
	for direction_data in directions:
		var attack_button := Button.new()
		attack_button.text = str(direction_data["label"])
		attack_button.custom_minimum_size = Vector2(132, 34) if direction_data["direction"] == Vector2i.ZERO else Vector2(64, 34)
		attack_button.add_theme_font_size_override("font_size", 8)
		attack_button.pressed.connect(_on_hero_attack_pressed.bind(direction_data["direction"]))
		hero_attack_panel.add_child(attack_button)
		hero_attack_buttons.append(attack_button)
		hero_attack_directions.append(direction_data["direction"])

	bar.add_child(hero_attack_panel)

	end_turn_button = Button.new()
	end_turn_button.text = "CONTINUAR"
	end_turn_button.custom_minimum_size = Vector2(150, 38)
	end_turn_button.add_theme_font_size_override("font_size", 11)
	end_turn_button.add_theme_stylebox_override("normal", _button_style(GOLD_COLOR, Color("#F0D76A"), 7, 1))
	end_turn_button.add_theme_color_override("font_color", Color("#182016"))
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	end_turn_button.visible = false
	bar.add_child(end_turn_button)

	return bar

func _start_battle() -> void:
	current_encounter_label = run_progress.encounter_label()
	selected_card_index = -1
	selected_unit_slot = -1
	selected_ium_index = -1
	status_label.text = "Preparando el catálogo de criaturas de Supabase..."

	var player_deck: Array[CardDefinition] = []
	var enemy_deck: Array[CardDefinition] = []
	var process_catalog: Array[CardDefinition] = []
	available_iums.clear()
	catalog_cards.clear()

	if not canon_repository.has_canon_data():
		status_label.text = "No hay criaturas de Supabase en caché. Conéctate para sincronizar el canon y vuelve a jugar. Pulsa ESC para volver."
		return

	catalog_cards = CardCatalog.from_canon(canon_repository)
	var canonical_creature_count := 0
	for canonical_card in catalog_cards:
		if canonical_card.card_type == CardDefinition.CardType.CREATURE:
			canonical_creature_count += 1
	if canonical_creature_count == 0:
		status_label.text = "Supabase no devolvió criaturas para el catálogo. Pulsa ESC para volver."
		return

	player_deck = CardCatalog.starter_deck_from_canon(canon_repository)
	enemy_deck = CardCatalog.enemy_deck_from_canon(canon_repository)

	for card in catalog_cards:
		if card.card_type == CardDefinition.CardType.IUM:
			if run_progress.mode == "bosses":
				available_iums.append(card)
		elif card.card_type == CardDefinition.CardType.PROCESS:
			process_catalog.append(card)

	if available_iums.is_empty() and run_progress.mode == "bosses":
		available_iums = CardCatalog.starter_ium_catalog()

	run_progress.ensure_deck(player_deck)
	player_deck = run_progress.build_player_deck(catalog_cards, player_deck)
	if player_deck.is_empty() or enemy_deck.is_empty():
		status_label.text = "No hay suficientes criaturas canónicas para construir ambos mazos. Pulsa ESC para volver."
		return
	enemy_deck = run_progress.build_enemy_deck(enemy_deck)

	engine = BattleEngine.new()
	engine.setup(player_deck, enemy_deck, process_catalog, available_iums, run_progress.selected_character_style)
	state = engine.get_state()
	status_label.text = "Tus guardias ya están desplegados. Pulsa INICIAR COMBATE."
	if run_progress.is_boss_encounter():
		state.enemy_hero.display_name = "Jefe de Garlia"
		state.enemy_hero.health = 45
		state.enemy_hero.attack = 8
		state.enemy_hero_max_health = 45
		state.enemy_health = 45

	engine.state_changed.connect(_refresh)
	engine.event_emitted.connect(_on_engine_event)
	engine.command_resolved.connect(_on_command_resolved)
	engine.battle_finished.connect(_on_battle_finished)

	player_name_label.text = state.player_hero.display_name
	enemy_name_label.text = state.enemy_hero.display_name
	_populate_ium_bar()
	_populate_loadout_inventory()
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
	attack_preview_slot = -1
	movement_preview_slot = -1
	status_label.text = state.hand[index].display_name
	_refresh()

func _on_board_gui_input(event: InputEvent, index: int) -> void:
	if state == null or state.is_finished():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Mientras el modo ataque está activo, ambos botones ejecutan el ataque
		# al pulsar una casilla marcada como objetivo.
		if attack_preview_slot >= 0 and _try_execute_attack_preview(index):
			get_viewport().set_input_as_handled()
			return
		if selected_card_index < 0 and _is_draggable_player_unit(index):
			var selected_card: CardDefinition = state.board.get_card(index)
			selected_unit_slot = index
			movement_preview_slot = -1
			attack_preview_slot = -1 if attack_preview_slot == index else index
			var targets: Array[int] = _attackable_slots_for(index)
			status_label.text = "%s · %d objetivo(s) de ataque" % [selected_card.display_name, targets.size()]
			_refresh()
		get_viewport().set_input_as_handled()
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

		if attack_preview_slot >= 0 and _try_execute_attack_preview(index):
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

func _try_execute_attack_preview(target_slot: int) -> bool:
	if state == null or attack_preview_slot < 0:
		return false
	if not _attackable_slots_for(attack_preview_slot).has(target_slot):
		return false

	var result: BattleResult
	if attack_preview_slot == state.player_hero_slot:
		var direction := Vector2i.ZERO
		if state.player_hero.tags.has("ataque_lineal"):
			var attacker_row: int = floori(float(attack_preview_slot) / float(BattleBoard.COLUMNS))
			var attacker_column: int = attack_preview_slot % BattleBoard.COLUMNS
			var target_row: int = floori(float(target_slot) / float(BattleBoard.COLUMNS))
			var target_column: int = target_slot % BattleBoard.COLUMNS
			if target_row < attacker_row:
				direction = Vector2i.UP
			elif target_row > attacker_row:
				direction = Vector2i.DOWN
			elif target_column < attacker_column:
				direction = Vector2i.LEFT
			else:
				direction = Vector2i.RIGHT
		result = engine.execute(BattleCommand.hero_attack(attack_preview_slot, direction))
	else:
		result = engine.execute(BattleCommand.attack(attack_preview_slot, target_slot))

	if result.success:
		selected_unit_slot = -1
		attack_preview_slot = -1
		movement_preview_slot = -1
	else:
		status_label.text = "ERROR · %s" % result.message
	_refresh()
	return true


func _is_draggable_player_unit(index: int) -> bool:
	if index < 0 or state == null:
		return false
	if state.board.get_owner(index) != BattleBoard.Owner.PLAYER:
		return false
	var unit: CardDefinition = state.board.get_card(index)
	return unit != null and unit.is_unit()

func _movement_slots_for(mover_slot: int) -> Array[int]:
	var targets: Array[int] = []
	if state == null or state.setup_phase or state.player_actions <= 0:
		return targets
	if mover_slot < 0 or mover_slot >= BattleBoard.CELL_COUNT:
		return targets
	var mover: CardDefinition = state.board.get_card(mover_slot)
	if state.board.get_owner(mover_slot) != BattleBoard.Owner.PLAYER or mover == null or not mover.is_unit():
		return targets
	for target_slot in range(BattleBoard.CELL_COUNT):
		if state.board.can_move(mover_slot, target_slot, BattleBoard.Owner.PLAYER, mover.movement):
			targets.append(target_slot)
	return targets

func _attackable_slots_for(attacker_slot: int) -> Array[int]:
	var targets: Array[int] = []
	if state == null or state.setup_phase or state.player_actions <= 0:
		return targets
	if attacker_slot < 0 or attacker_slot >= BattleBoard.CELL_COUNT:
		return targets

	var attacker: CardDefinition = state.board.get_card(attacker_slot)
	if state.board.get_owner(attacker_slot) != BattleBoard.Owner.PLAYER:
		return targets
	if attacker == null or not attacker.can_attack():
		return targets

	if attacker == state.player_hero:
		if attacker.tags.has("ataque_lineal"):
			var directions: Array[Vector2i] = [
				Vector2i.UP,
				Vector2i.DOWN,
				Vector2i.LEFT,
				Vector2i.RIGHT
			]
			for direction in directions:
				var target_slot: int = state.board.first_occupied_in_line(
					attacker_slot, direction, attacker.attack_range
				)
				if target_slot >= 0 and state.board.get_owner(target_slot) == BattleBoard.Owner.ENEMY:
					targets.append(target_slot)
		else:
			for target_slot in state.board.adjacent_indices(attacker_slot):
				if state.board.get_owner(target_slot) == BattleBoard.Owner.ENEMY and state.board.get_card(target_slot) != null:
					targets.append(target_slot)
		return targets

	for target_slot in state.board.indices_for_owner(BattleBoard.Owner.ENEMY):
		if state.board.distance(attacker_slot, target_slot) <= max(1, attacker.attack_range):
			targets.append(target_slot)
	return targets

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
		attack_preview_slot = -1
		movement_preview_slot = -1
		_refresh()
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
			attack_preview_slot = -1
			movement_preview_slot = -1
		return

	if _is_draggable_player_unit(index):
		selected_unit_slot = index
		movement_preview_slot = index
		attack_preview_slot = -1
		var selected_card: CardDefinition = state.board.get_card(index)
		status_label.text = "%s · movimiento posible" % selected_card.display_name
		_refresh()
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
			attack_preview_slot = -1
			movement_preview_slot = -1
			_refresh()
		return

func _on_hero_attack_pressed(direction: Vector2i) -> void:
	if state == null or state.is_finished() or selected_unit_slot != state.player_hero_slot:
		return
	var result: BattleResult = engine.execute(BattleCommand.hero_attack(state.player_hero_slot, direction))
	if result.success:
		selected_unit_slot = -1
		attack_preview_slot = -1
		movement_preview_slot = -1
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
	if state == null:
		return
	if state.is_finished():
		get_tree().reload_current_scene()
		return
	selected_card_index = -1
	selected_unit_slot = -1
	attack_preview_slot = -1
	movement_preview_slot = -1
	selected_ium_index = -1
	engine.execute(BattleCommand.end_turn())

func _on_command_resolved(result: BattleResult) -> void:
	status_label.text = result.message
	if not result.success:
		status_label.text = "ERROR · %s" % result.message
	_refresh()
	if result.success and state != null and not state.finished and not state.setup_phase and state.player_actions <= 0:
		call_deferred("_auto_end_turn_if_needed")

func _auto_end_turn_if_needed() -> void:
	if state == null or state.finished or state.player_actions > 0:
		return
	selected_card_index = -1
	selected_unit_slot = -1
	attack_preview_slot = -1
	movement_preview_slot = -1
	selected_ium_index = -1
	engine.execute(BattleCommand.end_turn())

func _on_engine_event(event: BattleEvent) -> void:
	if event.type == BattleEvent.EventType.DIAGNOSTIC:
		status_label.text = event.message

func _on_battle_finished(player_won: bool) -> void:
	var reward_message: String = run_progress.finish_battle(state, player_won, catalog_cards)
	status_label.text = ("VICTORIA" if player_won else "DERROTA") + reward_message
	end_turn_button.text = "CONTINUAR" if player_won else "REINTENTAR"
	end_turn_button.disabled = false
	process_button.disabled = true
	_refresh()

func _refresh() -> void:
	if state == null:
		return

	if state.setup_phase:
		turn_label.text = "%s · T0" % current_encounter_label
		actions_label.text = "DESPLIEGUE GRATUITO"
	else:
		turn_label.text = "%s · T%d" % [current_encounter_label, state.turn]
		actions_label.text = "ACCIONES %d/%d" % [state.player_actions, state.player_max_actions]
	# Los reyes no muestran barras de vida: el primer impacto los derrota.
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

	var attackable_slots: Array[int] = []
	if attack_preview_slot >= 0:
		attackable_slots = _attackable_slots_for(attack_preview_slot)
	var movement_slots: Array[int] = []
	if movement_preview_slot >= 0:
		movement_slots = _movement_slots_for(movement_preview_slot)
	for index in range(board_buttons.size()):
		var button: Button = board_buttons[index]
		var occupant: CardDefinition = state.board.get_card(index)
		var owner: int = state.board.get_owner(index)
		var selected: bool = index == selected_unit_slot
		var attackable: bool = attackable_slots.has(index)
		var movable: bool = movement_slots.has(index)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.expand_icon = true
		button.text = ""
		var piece_sprite: TextureRect = board_piece_sprites[index]
		var health_bar: ProgressBar = board_health_bars[index]
		if occupant != null:
			button.icon = null
			var is_hero: bool = occupant == state.player_hero or occupant == state.enemy_hero
			piece_sprite.texture = _pixel_sprite_for(occupant, is_hero)
			var tint_material := piece_sprite.material as ShaderMaterial
			var team_tint: Color = Color("#45E878") if owner == BattleBoard.Owner.PLAYER else Color("#4A9DFF")
			if tint_material != null:
				tint_material.set_shader_parameter("tint_color", team_tint)
				tint_material.set_shader_parameter("tint_strength", 0.82)
			health_bar.visible = occupant.is_unit()
			health_bar.max_value = float(max(occupant.max_health, 1))
			health_bar.value = float(clampi(occupant.health, 0, max(occupant.max_health, 1)))
			health_bar.add_theme_stylebox_override("fill", _style_box(team_tint, team_tint, 0, 0))
			button.tooltip_text = "%s · ATQ %d · VIDA %d/%d" % [occupant.display_name, occupant.attack, occupant.health, occupant.max_health]
		else:
			button.icon = null
			piece_sprite.texture = null
			health_bar.visible = false
			button.tooltip_text = "Casilla vacía"
		var cell_style: StyleBoxFlat = _cell_style(index, selected, attackable, movable)
		button.add_theme_stylebox_override("normal", cell_style)
		button.add_theme_stylebox_override("hover", _cell_style(index, selected, attackable, movable))
		button.add_theme_stylebox_override("pressed", _cell_style(index, selected, attackable, movable))
		button.add_theme_stylebox_override("focus", _cell_style(index, selected, attackable, movable))

	for index in range(mixer_buttons.size()):
		var mixer_button: Button = mixer_buttons[index]
		var mixer_card: CardDefinition = state.mixer.get_ium(index)
		mixer_button.text = mixer_card.display_name if mixer_card != null else "+"
		mixer_button.disabled = state.setup_phase or state.finished
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
		var etherium_cost: int = state.get_etherium_cost_for_card(card)
		hand_button.tooltip_text = card.description
		if state.setup_phase:
			hand_button.disabled = state.finished or not card.is_unit()
		else:
			hand_button.disabled = (
				state.finished
				or card.is_unit()
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
		ium_button.disabled = state.finished or state.setup_phase
		ium_button.add_theme_stylebox_override(
			"normal",
			_button_style(
				SELECTED_COLOR if index == selected_ium_index else SURFACE_ALT_COLOR,
				GOLD_COLOR if index == selected_ium_index else BORDER_COLOR,
				7,
				2 if index == selected_ium_index else 1
			)
		)

	end_turn_button.visible = state.setup_phase or state.finished
	end_turn_button.disabled = not state.setup_phase and not state.finished
	if state.setup_phase:
		end_turn_button.text = "INICIAR COMBATE"
	else:
		end_turn_button.text = "CONTINUAR" if state.finished and state.winner_is_player else ("REINTENTAR" if state.finished else "FIN DEL TURNO")
	hero_attack_panel.visible = state.player_hero != null and selected_unit_slot == state.player_hero_slot and not state.finished
	for direction_index in range(hero_attack_buttons.size()):
		var direction: Vector2i = hero_attack_directions[direction_index]
		var has_target := false
		if state.player_hero.tags.has("ataque_lineal"):
			var first_target: int = state.board.first_occupied_in_line(state.player_hero_slot, direction, state.player_hero.attack_range)
			has_target = first_target >= 0 and state.board.get_owner(first_target) == BattleBoard.Owner.ENEMY
		else:
			for adjacent_index in state.board.adjacent_indices(state.player_hero_slot):
				if state.board.get_owner(adjacent_index) == BattleBoard.Owner.ENEMY and state.board.get_card(adjacent_index) != null:
					has_target = true
					break
		hero_attack_buttons[direction_index].disabled = state.finished or state.player_actions <= 0 or not state.player_hero.can_attack() or not has_target

func _cell_style(index: int, selected: bool, attackable: bool = false, movable: bool = false) -> StyleBoxFlat:
	var row: int = floori(float(index) / float(BattleBoard.COLUMNS))
	var column: int = index % BattleBoard.COLUMNS
	var checker_color: Color = Color("#24483F") if (row + column) % 2 == 0 else Color("#293F58")
	var background: Color = checker_color
	if attackable:
		background = Color("#62531B")
	elif movable:
		background = Color("#205B49")
	var highlighted: bool = selected or attackable or movable
	var border_color: Color = GOLD_COLOR if selected or attackable else Color("#45E878") if movable else Color("#0B1712")
	return _style_box(background, border_color, 0, 3 if highlighted else 1)

func _scan_creature_sprites() -> void:
	creature_sprite_paths.clear()
	var directory := DirAccess.open("res://assets/criatures/")
	if directory == null:
		push_warning("No existe res://assets/criatures/. Se usarán placeholders para las criaturas.")
		return

	for file_name in directory.get_files():
		if not file_name.to_lower().ends_with(".png"):
			continue
		var key: String = _normalize_sprite_key(file_name.get_basename())
		if key.is_empty():
			continue
		creature_sprite_paths[key] = "res://assets/criatures/" + file_name


func _load_creature_sprite(card: CardDefinition) -> Texture2D:
	var candidate_keys: Array[String] = [
		_normalize_sprite_key(card.id),
		_normalize_sprite_key(card.canonical_id),
		_normalize_sprite_key(card.display_name)
	]
	for key in candidate_keys:
		if key.is_empty() or not creature_sprite_paths.has(key):
			continue
		var texture := load(str(creature_sprite_paths[key])) as Texture2D
		if texture != null:
			return texture
	return null


func _normalize_sprite_key(value: String) -> String:
	var normalized := value.get_file().get_basename().to_lower().strip_edges()
	normalized = normalized.replace(" ", "").replace("_", "").replace("-", "").replace(".", "")
	return normalized


func _pixel_sprite_for(card: CardDefinition, is_hero: bool = false) -> Texture2D:
	var cache_key: String = card.id + ("_hero" if is_hero else "_unit")
	if pixel_sprite_cache.has(cache_key):
		return pixel_sprite_cache[cache_key] as Texture2D

	if card.card_type == CardDefinition.CardType.CREATURE:
		var creature_texture: Texture2D = _load_creature_sprite(card)
		if creature_texture != null:
			pixel_sprite_cache[cache_key] = creature_texture
			return creature_texture

	# Placeholder: solo se usa si no existe una imagen PNG para esta criatura.
	var image: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var seed_value: int = abs(hash(card.id + card.display_name))
	var palette: Array[Color] = [
		Color("#78CEC1"), Color("#E3C34F"), Color("#D67A70"),
		Color("#9A8BE8"), Color("#78A6D9"), Color("#A8C96A")
	]
	var body_color: Color = palette[seed_value % palette.size()]
	var shadow_color: Color = body_color.darkened(0.45)
	var outline: Color = Color("#111A18")
	var skin_color: Color = Color("#E8C59B")
	var eye_color: Color = Color("#F7F3D8")

	# Sprite 64x64 en pixel art, dibujado con píxeles duros.
	_paint_pixel_rect(image, 20, 8, 24, 8, outline)
	_paint_pixel_rect(image, 16, 12, 32, 16, outline)
	_paint_pixel_rect(image, 20, 12, 24, 12, skin_color if is_hero else body_color)
	_paint_pixel_rect(image, 12, 28, 40, 20, outline)
	_paint_pixel_rect(image, 16, 28, 32, 16, body_color)
	_paint_pixel_rect(image, 20, 44, 8, 12, outline)
	_paint_pixel_rect(image, 36, 44, 8, 12, outline)
	_paint_pixel_rect(image, 20, 44, 4, 8, shadow_color)
	_paint_pixel_rect(image, 40, 44, 4, 8, shadow_color)
	_paint_pixel_rect(image, 8, 32, 8, 16, outline)
	_paint_pixel_rect(image, 48, 32, 8, 16, outline)
	_paint_pixel_rect(image, 8, 36, 8, 8, shadow_color)
	_paint_pixel_rect(image, 48, 36, 8, 8, shadow_color)
	_paint_pixel_rect(image, 20, 20, 8, 4, outline)
	_paint_pixel_rect(image, 36, 20, 8, 4, outline)
	_paint_pixel_rect(image, 24, 20, 4, 4, eye_color)
	_paint_pixel_rect(image, 36, 20, 4, 4, eye_color)
	if is_hero:
		_paint_pixel_rect(image, 20, 4, 4, 8, GOLD_COLOR)
		_paint_pixel_rect(image, 28, 0, 8, 12, GOLD_COLOR)
		_paint_pixel_rect(image, 40, 4, 4, 8, GOLD_COLOR)
		if card.tags.has("ataque_lineal"):
			_paint_pixel_rect(image, 48, 20, 4, 24, GOLD_COLOR)
			_paint_pixel_rect(image, 44, 16, 4, 4, GOLD_COLOR)
			_paint_pixel_rect(image, 44, 44, 4, 4, GOLD_COLOR)
			_paint_pixel_rect(image, 52, 28, 4, 8, skin_color)
	elif seed_value % 3 == 0:
		_paint_pixel_rect(image, 12, 8, 8, 12, outline)
		_paint_pixel_rect(image, 44, 8, 8, 12, outline)
		_paint_pixel_rect(image, 12, 8, 4, 8, shadow_color)
		_paint_pixel_rect(image, 48, 8, 4, 8, shadow_color)
	elif seed_value % 3 == 1:
		_paint_pixel_rect(image, 8, 20, 8, 8, outline)
		_paint_pixel_rect(image, 48, 20, 8, 8, outline)
		_paint_pixel_rect(image, 8, 20, 4, 4, body_color)
		_paint_pixel_rect(image, 52, 20, 4, 4, body_color)
	else:
		_paint_pixel_rect(image, 24, 28, 16, 8, skin_color)
		_paint_pixel_rect(image, 28, 32, 8, 4, outline)
	_paint_pixel_rect(image, 24, 36, 16, 4, shadow_color)
	if is_hero:
		_paint_pixel_rect(image, 24, 32, 16, 4, GOLD_COLOR)

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	pixel_sprite_cache[cache_key] = texture
	return texture

func _paint_pixel_rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(y, min(y + height, 64)):
		for px in range(x, min(x + width, 64)):
			image.set_pixel(px, py, color)

func _return_to_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_return_to_menu()
	
