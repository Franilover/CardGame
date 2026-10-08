extends Control

const NEXT_SCENE_PATH := "res://scenes/main_menu.tscn"
const MINIMUM_DISPLAY_TIME := 0.8

var elapsed_time := 0.0
var load_started := false
var load_finished := false
var load_failed := false
var next_scene: PackedScene

@onready var progress_bar: ProgressBar = $Center/Panel/Margin/Content/ProgressBar
@onready var status_label: Label = $Center/Panel/Margin/Content/Status
@onready var detail_label: Label = $Center/Panel/Margin/Content/Detail
@onready var percent_label: Label = $Center/Panel/Margin/Content/Percent

func _ready() -> void:
	progress_bar.value = 0.0
	status_label.text = "Inicializando Garlia"
	detail_label.text = "Preparando el núcleo del juego..."
	_start_loading()

func _process(delta: float) -> void:
	elapsed_time += delta

	if load_failed:
		if elapsed_time >= MINIMUM_DISPLAY_TIME:
			_fallback_load()
		return

	if not load_started:
		return

	var progress := []
	var status := ResourceLoader.load_threaded_get_status(NEXT_SCENE_PATH, progress)

	if not progress.is_empty():
		progress_bar.value = clamp(float(progress[0]) * 100.0, 0.0, 100.0)
		percent_label.text = "%d%%" % int(progress_bar.value)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			status_label.text = "Cargando Garlia"
			detail_label.text = "Preparando la escena principal..."
		ResourceLoader.THREAD_LOAD_LOADED:
			if not load_finished:
				load_finished = true
				next_scene = ResourceLoader.load_threaded_get(NEXT_SCENE_PATH) as PackedScene
				if next_scene == null:
					load_failed = true
					status_label.text = "Reintentando carga"
					detail_label.text = "La carga paralela no pudo entregar la escena."
					return

				progress_bar.value = 100.0
				percent_label.text = "100%"
				status_label.text = "Garlia listo"
				detail_label.text = "Entrando al juego..."

			if elapsed_time >= MINIMUM_DISPLAY_TIME:
				_open_game()

		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			load_failed = true
			status_label.text = "Reintentando carga"
			detail_label.text = "Preparando el juego con carga directa..."
			progress_bar.value = 0.0
			percent_label.text = "—"

func _start_loading() -> void:
	var error := ResourceLoader.load_threaded_request(
		NEXT_SCENE_PATH,
		"PackedScene",
		true
	)

	if error != OK:
		load_failed = true
		status_label.text = "Preparando Garlia"
		detail_label.text = "Inicializando la escena principal..."
		return

	load_started = true

func _fallback_load() -> void:
	if next_scene != null:
		_open_game()
		return

	next_scene = ResourceLoader.load(NEXT_SCENE_PATH, "PackedScene") as PackedScene

	if next_scene == null:
		status_label.text = "No se pudo iniciar"
		detail_label.text = "La escena principal no pudo cargarse."
		set_process(false)
		return

	progress_bar.value = 100.0
	percent_label.text = "100%"
	status_label.text = "Garlia listo"
	detail_label.text = "Entrando al juego..."
	_open_game()

func _open_game() -> void:
	if next_scene == null or not next_scene.can_instantiate():
		status_label.text = "Error de escena"
		detail_label.text = "La escena principal no puede iniciarse."
		set_process(false)
		return

	set_process(false)
	get_tree().change_scene_to_packed(next_scene)
