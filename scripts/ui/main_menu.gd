extends Control

@onready var canon_repository: Node = get_node("/root/GarliaCanonRepository")
@onready var run_progress: Node = get_node("/root/RunProgress")

const BATTLE_SCENE_PATH := "res://scenes/main.tscn"
const ADVENTURE_SCENE_PATH := "res://scenes/adventure.tscn"

var character_selector: VBoxContainer
var selector_mode: String = "exploration"

@onready var left_column: VBoxContainer = $Layout/Sidebar/SidebarContent
@onready var menu_container: VBoxContainer = $Layout/Sidebar/SidebarContent/Menu
@onready var status_label: Label = $Layout/Sidebar/SidebarContent/Status
@onready var play_button: Button = $Layout/Sidebar/SidebarContent/Menu/Jugar
@onready var boss_button: Button = $Layout/Sidebar/SidebarContent/Menu/Jefes
@onready var online_button: Button = $Layout/Sidebar/SidebarContent/Menu/Online
@onready var settings_button: Button = $Layout/Sidebar/SidebarContent/BottomMenu/Configuracion
@onready var quit_button: Button = $Layout/Sidebar/SidebarContent/BottomMenu/Salir
@onready var card_grid: GridContainer = $Layout/CatalogArea/CatalogScroll/CardGrid
@onready var card_count: Label = $Layout/CatalogArea/CatalogHeader/CatalogHeaderRow/CardCount

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	boss_button.pressed.connect(_on_bosses_pressed)
	online_button.pressed.connect(_on_online_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()
	status_label.text = canon_repository.get_status_text()
	await canon_repository.initialize()
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
	status_label.text = canon_repository.get_status_text()

func _on_online_pressed() -> void:
	status_label.text = "Online estará disponible más adelante."

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

func _populate_home_cards() -> void:
	for child in card_grid.get_children():
		child.queue_free()
	var cards: Array[CardDefinition] = CardCatalog.from_canon(canon_repository)
	for card in cards:
		if card == null:
			continue
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(120, 150)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var body := VBoxContainer.new()
		body.add_theme_constant_override("separation", 6)
		tile.add_child(body)
		var art := TextureRect.new()
		art.custom_minimum_size = Vector2(0, 88)
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var texture := _find_card_art(card)
		if texture != null:
			art.texture = texture
		body.add_child(art)
		var name_label := Label.new()
		name_label.text = card.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 13)
		body.add_child(name_label)
		var type_label := Label.new()
		type_label.text = _card_type_name(card)
		type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_label.add_theme_font_size_override("font_size", 10)
		type_label.add_theme_color_override("font_color", Color("#7FAF99"))
		body.add_child(type_label)
		card_grid.add_child(tile)
	card_count.text = str(cards.size())

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
