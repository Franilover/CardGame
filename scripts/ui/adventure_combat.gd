extends Control

@onready var canon_repository: Node = get_node("/root/GarliaCanonRepository")
@onready var run_progress: Node = get_node("/root/RunProgress")

const BG := Color("#071E16")
const PANEL := Color("#0F3024")
const ALT := Color("#123B2D")
const BORDER := Color("#2C6651")
const TEXT := Color("#E0EEE5")
const MUTED := Color("#7FAF99")
const GOLD := Color("#E3C34F")
const GREEN := Color("#45E878")
const RED := Color("#D67A70")
const PLAYER_MAX_HEALTH := 30
const PLAYER_ATTACK := 5

var creature: CardDefinition
var player_health: int = PLAYER_MAX_HEALTH
var creature_health: int = 1
var battle_finished: bool = false
var player_health_bar: ProgressBar
var creature_health_bar: ProgressBar
var player_health_label: Label
var creature_health_label: Label
var status_label: Label
var attack_button: Button
var retry_button: Button
var creature_title: Label
var creature_description: Label

func _ready() -> void:
	_build_ui()
	await canon_repository.initialize()
	_load_creature()
	_refresh()

func _style(background: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(0)
	return box

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var heading := Label.new()
	heading.text = "COMBATE DE AVENTURA"
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", TEXT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var back := Button.new()
	back.text = "HUIR"
	back.pressed.connect(_return_to_adventure)
	header.add_child(back)

	var subtitle := Label.new()
	subtitle.text = "Un encuentro individual: tú contra una sola criatura."
	subtitle.add_theme_color_override("font_color", MUTED)
	root.add_child(subtitle)

	var arena := HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.add_theme_constant_override("separation", 18)
	root.add_child(arena)

	var player_panel := _fighter_panel("TÚ", GREEN)
	arena.add_child(player_panel)
	var creature_panel := _fighter_panel("CRIATURA", RED)
	arena.add_child(creature_panel)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	root.add_child(actions)

	attack_button = Button.new()
	attack_button.text = "ATACAR"
	attack_button.custom_minimum_size = Vector2(180, 52)
	attack_button.add_theme_font_size_override("font_size", 18)
	attack_button.pressed.connect(_player_attack)
	actions.add_child(attack_button)

	retry_button = Button.new()
	retry_button.text = "VOLVER A AVENTURA"
	retry_button.custom_minimum_size = Vector2(180, 52)
	retry_button.visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	actions.add_child(retry_button)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", GOLD)
	root.add_child(status_label)

func _fighter_panel(label_text: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(PANEL, accent, 2))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = label_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", accent)
	column.add_child(title)
	if label_text == "TÚ":
		var portrait := Label.new()
		portrait.text = "◆"
		portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		portrait.add_theme_font_size_override("font_size", 72)
		portrait.add_theme_color_override("font_color", accent)
		column.add_child(portrait)
		var stats := Label.new()
		stats.text = "ATQ %d" % PLAYER_ATTACK
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.add_theme_color_override("font_color", TEXT)
		column.add_child(stats)
		player_health_bar = _health_bar(accent)
		column.add_child(player_health_bar)
		player_health_label = Label.new()
		player_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_health_label.add_theme_color_override("font_color", TEXT)
		column.add_child(player_health_label)
	else:
		creature_title = Label.new()
		creature_title.text = "Buscando criatura..."
		creature_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		creature_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		creature_title.add_theme_font_size_override("font_size", 20)
		creature_title.add_theme_color_override("font_color", TEXT)
		column.add_child(creature_title)
		creature_description = Label.new()
		creature_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		creature_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		creature_description.add_theme_color_override("font_color", MUTED)
		column.add_child(creature_description)
		var stats := Label.new()
		stats.text = "ATQ —"
		stats.name = "CreatureStats"
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.add_theme_color_override("font_color", TEXT)
		column.add_child(stats)
		creature_health_bar = _health_bar(accent)
		column.add_child(creature_health_bar)
		creature_health_label = Label.new()
		creature_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		creature_health_label.add_theme_color_override("font_color", TEXT)
		column.add_child(creature_health_label)
	return panel

func _health_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 24)
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 1
	bar.value = 1
	bar.add_theme_stylebox_override("background", _style(Color("#101714"), Color("#101714"), 0))
	bar.add_theme_stylebox_override("fill", _style(fill_color, fill_color, 0))
	return bar

func _load_creature() -> void:
	var selected_id: String = run_progress.selected_adventure_creature_id
	for card in CardCatalog.from_canon(canon_repository):
		if card != null and card.card_type == CardDefinition.CardType.CREATURE and card.id == selected_id:
			creature = card.make_runtime_copy()
			break
	if creature == null:
		status_label.text = "No se encontró la criatura canónica. Vuelve a Aventura y selecciona otra."
		attack_button.disabled = true
		return
	creature_health = max(1, creature.max_health)
	creature_title.text = creature.display_name
	creature_description.text = creature.description
	var stats_label := creature_title.get_parent().get_node_or_null("CreatureStats") as Label
	if stats_label != null:
		stats_label.text = "ATQ %d" % creature.attack
	status_label.text = "Derrota a la criatura para desbloquear su carta."

func _player_attack() -> void:
	if battle_finished or creature == null:
		return
	creature_health = max(0, creature_health - PLAYER_ATTACK)
	if creature_health <= 0:
		battle_finished = true
		var newly_unlocked := run_progress.unlock_creature_after_adventure_victory(creature.id)
		status_label.text = "¡VICTORIA! Carta desbloqueada: %s." % creature.display_name if newly_unlocked else "¡VICTORIA! %s ya estaba desbloqueada." % creature.display_name
		attack_button.disabled = true
		retry_button.visible = true
		retry_button.text = "VOLVER A AVENTURA"
		_refresh()
		return

	player_health = max(0, player_health - max(1, creature.attack))
	if player_health <= 0:
		battle_finished = true
		status_label.text = "DERROTA. La criatura sigue sin desbloquearse."
		attack_button.disabled = true
		retry_button.visible = true
		retry_button.text = "REINTENTAR"
	_refresh()

func _refresh() -> void:
	if player_health_bar != null:
		player_health_bar.max_value = PLAYER_MAX_HEALTH
		player_health_bar.value = player_health
		player_health_label.text = "VIDA %d / %d" % [player_health, PLAYER_MAX_HEALTH]
	if creature_health_bar != null and creature != null:
		creature_health_bar.max_value = max(1, creature.max_health)
		creature_health_bar.value = creature_health
		creature_health_label.text = "VIDA %d / %d" % [creature_health, max(1, creature.max_health)]

func _on_retry_pressed() -> void:
	if player_health <= 0 and creature != null:
		player_health = PLAYER_MAX_HEALTH
		creature_health = max(1, creature.max_health)
		battle_finished = false
		attack_button.disabled = false
		retry_button.visible = false
		status_label.text = "Inténtalo de nuevo. Derrota a la criatura para desbloquearla."
		_refresh()
		return
	_return_to_adventure()


func _return_to_adventure() -> void:
	get_tree().change_scene_to_file("res://scenes/adventure.tscn")
