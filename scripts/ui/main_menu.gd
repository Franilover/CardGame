extends Control

@onready var canon_repository: Node = get_node("/root/GarliaCanonRepository")
@onready var run_progress: Node = get_node("/root/RunProgress")

const BATTLE_SCENE_PATH := "res://scenes/main.tscn"
const ADVENTURE_SCENE_PATH := "res://scenes/adventure.tscn"
const CARDS_SCENE_PATH := "res://scenes/cards.tscn"

var character_selector: VBoxContainer
var selector_mode: String = "exploration"

@onready var content: VBoxContainer = $Center/Panel/Margin/Content
@onready var menu_container: VBoxContainer = $Center/Panel/Margin/Content/Menu
@onready var status_label: Label = $Center/Panel/Margin/Content/Status
@onready var play_button: Button = $Center/Panel/Margin/Content/Menu/Jugar
@onready var boss_button: Button = $Center/Panel/Margin/Content/Menu/Jefes
@onready var online_button: Button = $Center/Panel/Margin/Content/Menu/Online
@onready var cards_button: Button = $Center/Panel/Margin/Content/Menu/Cartas
@onready var settings_button: Button = $Center/Panel/Margin/Content/Menu/Configuracion
@onready var quit_button: Button = $Center/Panel/Margin/Content/Menu/Salir

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	boss_button.pressed.connect(_on_bosses_pressed)
	online_button.pressed.connect(_on_online_pressed)
	cards_button.pressed.connect(_on_cards_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()
	status_label.text = canon_repository.get_status_text()

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
	content.add_child(character_selector)
	content.move_child(character_selector, status_label.get_index())

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

func _on_cards_pressed() -> void:
	get_tree().change_scene_to_file(CARDS_SCENE_PATH)

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
