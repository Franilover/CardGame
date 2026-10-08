extends Control

@onready var canon_repository: Node = get_node("/root/GarliaCanonRepository")

const NEXT_SCENE_PATH := "res://scenes/main_menu.tscn"
const MINIMUM_DISPLAY_TIME := 0.8

var elapsed_time := 0.0
var loaded_scene: PackedScene
var scene_loading := false
var boot_finished := false

@onready var progress_bar: ProgressBar = $Center/Panel/Margin/Content/ProgressBar
@onready var status_label: Label = $Center/Panel/Margin/Content/Status
@onready var detail_label: Label = $Center/Panel/Margin/Content/Detail
@onready var percent_label: Label = $Center/Panel/Margin/Content/Percent

func _ready() -> void:
	progress_bar.value = 0.0
	status_label.text = "INICIALIZANDO"
	detail_label.text = "Preparando Garlia..."
	_boot()

func _process(delta: float) -> void:
	elapsed_time += delta

	if not scene_loading:
		return

	var progress: Array = []
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(NEXT_SCENE_PATH, progress)

	if not progress.is_empty():
		progress_bar.value = clamp(float(progress[0]) * 100.0, 0.0, 100.0)
		percent_label.text = "%d%%" % int(progress_bar.value)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			status_label.text = "CARGANDO"
			detail_label.text = "Preparando interfaz..."
		ResourceLoader.THREAD_LOAD_LOADED:
			if loaded_scene == null:
				loaded_scene = ResourceLoader.load_threaded_get(NEXT_SCENE_PATH) as PackedScene

			progress_bar.value = 100.0
			percent_label.text = "100%"
			status_label.text = "LISTO"
			detail_label.text = canon_repository.get_status_text()

			if boot_finished and elapsed_time >= MINIMUM_DISPLAY_TIME:
				_open_menu()

		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			loaded_scene = ResourceLoader.load(NEXT_SCENE_PATH, "PackedScene") as PackedScene
			if loaded_scene != null:
				progress_bar.value = 100.0
				percent_label.text = "100%"
				status_label.text = "LISTO"
				detail_label.text = canon_repository.get_status_text()
				if boot_finished:
					_open_menu()
			else:
				status_label.text = "ERROR"
				detail_label.text = "No se pudo cargar el menú principal."
				set_process(false)

func _boot() -> void:
	var error: Error = ResourceLoader.load_threaded_request(NEXT_SCENE_PATH, "PackedScene", true)
	if error != OK:
		loaded_scene = ResourceLoader.load(NEXT_SCENE_PATH, "PackedScene") as PackedScene

	scene_loading = true
	status_label.text = "SINCRONIZANDO"
	detail_label.text = "Consultando el canon..."
	var online: bool = await canon_repository.initialize()
	boot_finished = true

	if online:
		detail_label.text = "Canon sincronizado."
	elif canon_repository.has_canon_data():
		detail_label.text = "Usando canon en caché."
	else:
		detail_label.text = "Modo local."

func _open_menu() -> void:
	if loaded_scene == null or not loaded_scene.can_instantiate():
		status_label.text = "ERROR"
		detail_label.text = "La escena del menú no puede iniciarse."
		set_process(false)
		return

	set_process(false)
	get_tree().change_scene_to_packed(loaded_scene)
