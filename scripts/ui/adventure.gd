extends Control

@onready var canon_repository: Node = get_node("/root/GarliaCanonRepository")
@onready var run_progress: Node = get_node("/root/RunProgress")

const COMBAT_SCENE_PATH := "res://scenes/adventure_combat.tscn"
const BG := Color("#071E16")
const PANEL := Color("#0F3024")
const ALT := Color("#123B2D")
const BORDER := Color("#2C6651")
const TEXT := Color("#E0EEE5")
const MUTED := Color("#7FAF99")
const GOLD := Color("#E3C34F")

var content: VBoxContainer
var status_label: Label
var list_root: VBoxContainer
var collection_label: Label

func _ready() -> void:
	_build_ui()
	await canon_repository.initialize()
	_populate_creatures()

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
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "AVENTURA"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := Button.new()
	back.text = "MENÚ"
	back.pressed.connect(_return_to_menu)
	header.add_child(back)

	var subtitle := Label.new()
	subtitle.text = "Explora, encuentra criaturas y desbloquea sus cartas al derrotarlas."
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(subtitle)

	collection_label = Label.new()
	collection_label.add_theme_color_override("font_color", GOLD)
	content.add_child(collection_label)

	var divider := HSeparator.new()
	content.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	list_root = VBoxContainer.new()
	list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_root.add_theme_constant_override("separation", 7)
	scroll.add_child(list_root)

	status_label = Label.new()
	status_label.text = "Cargando el catálogo canónico..."
	status_label.add_theme_color_override("font_color", MUTED)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status_label)

func _populate_creatures() -> void:
	for child in list_root.get_children():
		child.queue_free()

	var creatures: Array[CardDefinition] = []
	for card in CardCatalog.from_canon(canon_repository):
		if card != null and card.card_type == CardDefinition.CardType.CREATURE:
			creatures.append(card)

	collection_label.text = "COLECCIÓN · %d / %d criaturas desbloqueadas" % [run_progress.unlocked_creature_ids.size(), creatures.size()]
	if creatures.is_empty():
		status_label.text = "No hay criaturas canónicas disponibles. Conéctate y sincroniza Supabase."
		return

	creatures.sort_custom(func(a: CardDefinition, b: CardDefinition) -> bool:
		return a.display_name.naturalcasecmp_to(b.display_name) < 0
	)
	for creature in creatures:
		var unlocked := run_progress.is_creature_unlocked(creature.id)
		var button := Button.new()
		button.custom_minimum_size.y = 68
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var state_text := "DESBLOQUEADA" if unlocked else "NUEVA · DERROTA PARA DESBLOQUEAR"
		button.text = "%s\nATQ %d · VIDA %d    |    %s" % [creature.display_name, creature.attack, creature.max_health, state_text]
		button.add_theme_stylebox_override("normal", _style(PANEL, GOLD if unlocked else BORDER, 1))
		button.add_theme_stylebox_override("hover", _style(ALT, GOLD, 2))
		button.add_theme_stylebox_override("pressed", _style(ALT, GOLD, 2))
		button.pressed.connect(_start_encounter.bind(creature.id))
		list_root.add_child(button)

	status_label.text = "Selecciona una criatura para iniciar un combate individual. Solo una victoria en Aventura puede desbloquear su carta."

func _start_encounter(creature_id: String) -> void:
	run_progress.mode = "adventure"
	run_progress.selected_adventure_creature_id = creature_id
	get_tree().change_scene_to_file(COMBAT_SCENE_PATH)

func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
