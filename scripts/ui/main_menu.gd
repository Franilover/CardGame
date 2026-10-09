extends Control

@onready var canon_repository: Node = get_node("/root/GarliaCanonRepository")
@onready var run_progress: Node = get_node("/root/RunProgress")

const BATTLE_SCENE_PATH := "res://scenes/main.tscn"
const ADVENTURE_SCENE_PATH := "res://scenes/adventure.tscn"

var character_selector: VBoxContainer
var selector_mode: String = "exploration"
var show_discoveries: bool = false
var loadout_row: HBoxContainer
var king_selector: OptionButton

@onready var left_column: VBoxContainer = $Layout/Sidebar/SidebarContent
@onready var menu_container: VBoxContainer = $Layout/Sidebar/SidebarContent/Menu
@onready var status_label: Label = $Layout/Sidebar/SidebarContent/Status
@onready var play_button: Button = $Layout/Sidebar/SidebarContent/Menu/Jugar
@onready var boss_button: Button = $Layout/Sidebar/SidebarContent/Menu/Jefes
@onready var online_button: Button = $Layout/Sidebar/SidebarContent/Menu/Online
@onready var discoveries_button: Button = $Layout/Sidebar/SidebarContent/Menu/Descubrimientos
@onready var settings_button: Button = $Layout/Sidebar/SidebarContent/BottomMenu/Configuracion
@onready var quit_button: Button = $Layout/Sidebar/SidebarContent/BottomMenu/Salir
@onready var card_grid: GridContainer = $Layout/CatalogArea/CatalogScroll/CardGrid
@onready var card_count: Label = $Layout/CatalogArea/CatalogHeader/CatalogHeaderRow/CardCount
@onready var loadout_scroll: ScrollContainer = $Layout/CatalogArea/LoadoutScroll

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	boss_button.pressed.connect(_on_bosses_pressed)
	online_button.pressed.connect(_on_online_pressed)
	discoveries_button.pressed.connect(_on_discoveries_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()
	status_label.text = ""
	await canon_repository.initialize()
	var starter_cards: Array[CardDefinition] = CardCatalog.starter_deck_from_canon(canon_repository)
	run_progress.initialize_collection(starter_cards)
	_build_loadout_row()
	_populate_home_cards()

func _on_play_pressed() -> void:
	run_progress.start_mode("adventure")
	get_tree().change_scene_to_file(ADVENTURE_SCENE_PATH)

func _on_bosses_pressed() -> void:
	_show_character_selector("combat")

func _show_character_selector(mode_name: String) -> void:
	selector_mode = mode_name
	if mode_name == "combat":
		run_progress.start_mode("combat")
	menu_container.visible = false
	status_label.text = "MODO COMBATE · Elige tu personaje."
	if character_selector != null:
		character_selector.queue_free()
	character_selector = VBoxContainer.new()
	character_selector.name = "CharacterSelector"
	character_selector.add_theme_constant_override("separation", 10)
	left_column.add_child(character_selector)
	left_column.move_child(character_selector, status_label.get_index())

	var guardian_button := Button.new()
	guardian_button.custom_minimum_size.y = 76
	guardian_button.text = "REY GUARDIÁN\n3 guardias · golpe circular adyacente"
	guardian_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guardian_button.pressed.connect(_on_character_selected.bind("guardian"))
	character_selector.add_child(guardian_button)

	var archer_button := Button.new()
	archer_button.custom_minimum_size.y = 76
	archer_button.text = "REY ARQUERO\n1 guardia · disparo a distancia en línea recta"
	archer_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	archer_button.pressed.connect(_on_character_selected.bind("archer"))
	character_selector.add_child(archer_button)

	var back_button := Button.new()
	back_button.text = "VOLVER"
	back_button.custom_minimum_size.y = 38
	back_button.pressed.connect(_on_character_selector_back)
	character_selector.add_child(back_button)

func _on_character_selected(character_style: String) -> void:
	run_progress.selected_character_style = character_style
	status_label.text = "Preparando combate con %s..." % ("Rey Arquero" if character_style == "archer" else "Rey Guardián")
	set_process_input(false)
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)

func _on_character_selector_back() -> void:
	if character_selector != null:
		character_selector.queue_free()
		character_selector = null
	menu_container.visible = true
	status_label.text = ""

func _on_online_pressed() -> void:
	status_label.text = "Online estará disponible más adelante."

func _on_discoveries_pressed() -> void:
	show_discoveries = not show_discoveries
	discoveries_button.text = "VOLVER A CARTAS" if show_discoveries else "DESCUBRIMIENTOS"
	_populate_home_cards()
	_build_loadout_row()
	loadout_scroll.visible = not show_discoveries
	$Layout/CatalogArea/CatalogHeader/CatalogHeaderRow/CatalogTitle.text = "DESCUBRIMIENTOS" if show_discoveries else "CARTAS"

func _on_settings_pressed() -> void:
	status_label.text = "La configuración se agregará aquí."

func _on_quit_pressed() -> void:
	get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if menu_container.visible and play_button.has_focus():
				_on_play_pressed()
		elif event.keycode == KEY_ESCAPE:
			if character_selector != null:
				_on_character_selector_back()
			else:
				_on_quit_pressed()

func _build_loadout_row() -> void:
	var row_node := loadout_scroll.get_node_or_null("LoadoutRow")
	if row_node == null:
		return
	for child in row_node.get_children():
		row_node.remove_child(child)
		child.queue_free()
	loadout_row = row_node as HBoxContainer
	loadout_row.add_theme_constant_override("separation", 8)

	var king_panel := PanelContainer.new()
	king_panel.custom_minimum_size = Vector2(130, 76)
	king_panel.add_theme_stylebox_override("panel", _loadout_style())
	var king_content := VBoxContainer.new()
	king_content.add_theme_constant_override("separation", 3)
	king_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	king_panel.add_child(king_content)
	var king_label := Label.new()
	king_label.text = "REY"
	king_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	king_label.add_theme_font_size_override("font_size", 10)
	king_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	king_content.add_child(king_label)
	king_selector = OptionButton.new()
	king_selector.add_item("Guardián", 0)
	king_selector.add_item("Arquero", 1)
	king_selector.select(1 if run_progress.selected_character_style == "archer" else 0)
	king_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	king_selector.item_selected.connect(_on_king_selected)
	king_content.add_child(king_selector)
	loadout_row.add_child(king_panel)

	var cards_by_id: Dictionary = {}
	for card in CardCatalog.from_canon(canon_repository):
		if card != null and not cards_by_id.has(card.id):
			cards_by_id[card.id] = card

	for index in range(run_progress.loadout_ids.size()):
		var card_id: String = run_progress.loadout_ids[index]
		var card: CardDefinition = cards_by_id.get(card_id) as CardDefinition
		var slot := PanelContainer.new()
		slot.set_script(load("res://scripts/ui/card_loadout_item.gd"))
		slot.set("slot_index", index)
		slot.set("card_id", card_id)
		slot.custom_minimum_size = Vector2(92, 76)
		slot.add_theme_stylebox_override("panel", _loadout_style())
		slot.connect("card_dropped", _on_loadout_card_dropped)
		slot.connect("slot_activated", _on_loadout_slot_activated)
		var slot_content := VBoxContainer.new()
		slot_content.add_theme_constant_override("separation", 2)
		slot_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(slot_content)
		var number_label := Label.new()
		number_label.text = str(index + 1)
		number_label.add_theme_font_size_override("font_size", 9)
		number_label.add_theme_color_override("font_color", Color("#7FAF99"))
		number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_content.add_child(number_label)
		var name_label := Label.new()
		name_label.text = card.display_name if card != null else "ARRASTRA"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color("#E0EEE5") if card != null else Color("#7FAF99"))
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_content.add_child(name_label)
		loadout_row.add_child(slot)

func _loadout_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0F3024")
	style.border_color = Color("#2C6651")
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	return style

func _on_king_selected(index: int) -> void:
	run_progress.selected_character_style = "archer" if index == 1 else "guardian"
	run_progress._save_progress()

func _on_loadout_card_dropped(slot_index: int, data: Dictionary) -> void:
	var card_id := str(data.get("card_id", ""))
	var source_slot := int(data.get("source_slot", -1))
	if source_slot >= 0:
		run_progress.move_loadout_card(source_slot, slot_index)
	elif not run_progress.set_loadout_card(slot_index, card_id):
		status_label.text = "No tienes otra copia de esa carta."
		return
	status_label.text = ""
	_build_loadout_row()
	_populate_home_cards()

func _on_loadout_slot_activated(slot_index: int) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		run_progress.set_loadout_card(slot_index, "")
		_build_loadout_row()
		_populate_home_cards()

func _populate_home_cards() -> void:
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()
	var cards: Array[CardDefinition] = CardCatalog.from_canon(canon_repository)
	var visible_count := 0
	for card in cards:
		if card == null:
			continue
		var owned_count: int = run_progress.get_owned_count(card.id)
		var should_show: bool = run_progress.is_card_discovered(card) if show_discoveries else owned_count > 0
		if not should_show:
			continue
		visible_count += 1
		var tile := PanelContainer.new()
		if not show_discoveries and owned_count > 0:
			tile.set_script(load("res://scripts/ui/card_loadout_item.gd"))
			tile.set("card_id", card.id)
			tile.set("slot_index", -1)
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.035, 0.105, 0.075, 1)
		card_style.border_width_left = 1
		card_style.border_width_top = 1
		card_style.border_width_right = 1
		card_style.border_width_bottom = 1
		card_style.border_color = Color(0.16, 0.43, 0.29, 1)
		card_style.corner_radius_top_left = 4
		card_style.corner_radius_top_right = 4
		card_style.corner_radius_bottom_right = 4
		card_style.corner_radius_bottom_left = 4
		tile.add_theme_stylebox_override("panel", card_style)
		tile.custom_minimum_size = Vector2(120, 150)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var body := VBoxContainer.new()
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_theme_constant_override("separation", 6)
		tile.add_child(body)
		var art := TextureRect.new()
		art.custom_minimum_size = Vector2(0, 88)
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var texture := _find_card_art(card)
		if texture != null:
			art.texture = texture
		body.add_child(art)
		var name_label := Label.new()
		name_label.text = card.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 13)
		body.add_child(name_label)
		var type_label := Label.new()
		type_label.text = _card_type_name(card) if show_discoveries else "%s · x%d" % [_card_type_name(card), owned_count]
		type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		type_label.add_theme_font_size_override("font_size", 10)
		type_label.add_theme_color_override("font_color", Color("#7FAF99"))
		body.add_child(type_label)
		card_grid.add_child(tile)
	card_count.text = str(visible_count)

func _find_card_art(card: CardDefinition) -> Texture2D:
	var folders: Array[String] = ["res://assets/criatures/", "res://assets/art/items/"]
	var keys: Array[String] = [
		_normalize_art_key(card.id),
		_normalize_art_key(card.canonical_id),
		_normalize_art_key(card.display_name)
	]
	for folder in folders:
		var directory := DirAccess.open(folder)
		if directory == null:
			continue
		for file_name in directory.get_files():
			if not file_name.to_lower().ends_with(".png"):
				continue
			if keys.has(_normalize_art_key(file_name.get_basename())):
				return load(folder + file_name) as Texture2D
	return null

func _normalize_art_key(value: String) -> String:
	return value.get_file().get_basename().to_lower().replace(" ", "").replace("_", "").replace("-", "").replace(".", "")

func _card_type_name(card: CardDefinition) -> String:
	match card.card_type:
		CardDefinition.CardType.CREATURE:
			return "CRIATURA"
		CardDefinition.CardType.OBJECT:
			return "OBJETO"
		CardDefinition.CardType.IUM:
			return "IUM"
		CardDefinition.CardType.PROCESS:
			return "PROCESO"
		CardDefinition.CardType.ORIS:
			return "ORIS"
		_:
			return "CARTA"
