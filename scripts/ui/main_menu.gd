extends Control

const BATTLE_SCENE_PATH := "res://scenes/main.tscn"
const CARDS_SCENE_PATH := "res://scenes/cards.tscn"

@onready var status_label: Label = $Center/Panel/Margin/Content/Status
@onready var play_button: Button = $Center/Panel/Margin/Content/Menu/Jugar
@onready var online_button: Button = $Center/Panel/Margin/Content/Menu/Online
@onready var cards_button: Button = $Center/Panel/Margin/Content/Menu/Cartas
@onready var settings_button: Button = $Center/Panel/Margin/Content/Menu/Configuracion
@onready var quit_button: Button = $Center/Panel/Margin/Content/Menu/Salir

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	online_button.pressed.connect(_on_online_pressed)
	cards_button.pressed.connect(_on_cards_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()
	status_label.text = GarliaCanon.get_status_text()

func _on_play_pressed() -> void:
	status_label.text = "Preparando partida..."
	set_process_input(false)
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)

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
			if play_button.has_focus():
				_on_play_pressed()
		elif event.keycode == KEY_ESCAPE:
			_on_quit_pressed()
