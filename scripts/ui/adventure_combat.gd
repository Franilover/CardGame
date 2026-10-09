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
const BOARD_SIZE: int = 3
const CELL_COUNT: int = BOARD_SIZE * BOARD_SIZE
const PLAYER_MAX_HEALTH: int = 30
const PLAYER_ATTACK: int = 5
const PLAYER_MOVEMENT: int = 1
const ACTIONS_PER_TURN: int = 2
const PLAYER_START_SLOT: int = 7
const CREATURE_START_SLOT: int = 1

var creature: CardDefinition
var player_health: int = PLAYER_MAX_HEALTH
var creature_health: int = 1
var player_slot: int = PLAYER_START_SLOT
var creature_slot: int = CREATURE_START_SLOT
var player_actions: int = ACTIONS_PER_TURN
var turn_number: int = 1
var battle_finished: bool = false
var movement_preview: bool = false
var attack_preview: bool = false
var board_buttons: Array[Button] = []
var status_label: Label
var actions_label: Label
var retry_button: Button
var creature_title: Label
var creature_description: Label
var creature_portrait: TextureRect

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
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var heading := Label.new()
	heading.text = "AVENTURA"
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", TEXT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var back := Button.new()
	back.text = "HUIR"
	back.pressed.connect(_return_to_adventure)
	header.add_child(back)

	var board_center := CenterContainer.new()
	board_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(board_center)
	var board_panel := PanelContainer.new()
	board_panel.add_theme_stylebox_override("panel", _style(PANEL, BORDER, 2))
	board_center.add_child(board_panel)
	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 8)
	board_margin.add_theme_constant_override("margin_right", 8)
	board_margin.add_theme_constant_override("margin_top", 8)
	board_margin.add_theme_constant_override("margin_bottom", 8)
	board_panel.add_child(board_margin)
	var grid := GridContainer.new()
	grid.columns = BOARD_SIZE
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	board_margin.add_child(grid)

	for index in range(CELL_COUNT):
		var cell := Button.new()
		cell.custom_minimum_size = Vector2(116, 91)
		cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		cell.expand_icon = true
		cell.add_theme_font_size_override("font_size", 12)
		cell.gui_input.connect(_on_cell_gui_input.bind(index))
		grid.add_child(cell)
		board_buttons.append(cell)

	actions_label = Label.new()
	actions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions_label.add_theme_font_size_override("font_size", 14)
	actions_label.add_theme_color_override("font_color", GOLD)
	root.add_child(actions_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)
	retry_button = Button.new()
	retry_button.text = "VOLVER A AVENTURA"
	retry_button.custom_minimum_size = Vector2(190, 42)
	retry_button.visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	actions.add_child(retry_button)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", GOLD)
	root.add_child(status_label)

func _load_creature() -> void:
	var selected_id: String = run_progress.selected_adventure_creature_id
	for card in CardCatalog.from_canon(canon_repository):
		if card != null and card.card_type == CardDefinition.CardType.CREATURE and card.id == selected_id:
			creature = card.make_runtime_copy()
			break
	if creature == null:
		status_label.text = "No se encontró la criatura canónica. Vuelve a Aventura y selecciona otra."
		return
	creature_health = max(1, creature.max_health)
	creature_title.text = creature.display_name
	creature_description = Label.new()
	creature_description.text = creature.description
	creature_description.visible = false
	creature_portrait = TextureRect.new()
	creature_portrait.texture = _load_creature_portrait(creature)
	status_label.text = "Derrota a la criatura para desbloquear su carta."

func _load_creature_portrait(card: CardDefinition) -> Texture2D:
	var directory := DirAccess.open("res://assets/criatures/")
	if directory == null:
		return null
	var wanted: Array[String] = [
		_normalize_sprite_key(card.id),
		_normalize_sprite_key(card.canonical_id),
		_normalize_sprite_key(card.display_name)
	]
	for file_name in directory.get_files():
		if not file_name.to_lower().ends_with(".png"):
			continue
		if wanted.has(_normalize_sprite_key(file_name.get_basename())):
			return load("res://assets/criatures/" + file_name) as Texture2D
	return null

func _normalize_sprite_key(value: String) -> String:
	var normalized := value.get_file().get_basename().to_lower().strip_edges()
	return normalized.replace(" ", "").replace("_", "").replace("-", "").replace(".", "")

func _on_cell_gui_input(event: InputEvent, index: int) -> void:
	if battle_finished or creature == null or not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if index == player_slot:
			attack_preview = true
			movement_preview = false
			status_label.text = "Selecciona una casilla enemiga marcada para atacar."
		elif attack_preview and index == creature_slot and _can_attack_from(player_slot, creature_slot, PLAYER_ATTACK_RANGE):
			_player_attack()
		_refresh()
		get_viewport().set_input_as_handled()
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if attack_preview and index == creature_slot:
		if _can_attack_from(player_slot, creature_slot, PLAYER_ATTACK_RANGE):
			_player_attack()
		else:
			status_label.text = "La criatura está fuera de alcance."
		_refresh()
		get_viewport().set_input_as_handled()
		return

	if index == player_slot:
		movement_preview = true
		attack_preview = false
		status_label.text = "Elige una casilla verde para moverte."
	elif movement_preview and _movement_targets(player_slot).has(index):
		_move_player(index)
	elif index == creature_slot:
		movement_preview = false
		attack_preview = false
		status_label.text = "Clic derecho sobre tu casilla para mostrar los objetivos de ataque."
	else:
		movement_preview = false
		attack_preview = false
		status_label.text = "Selecciona tu casilla para ver movimientos posibles."
	_refresh()
	get_viewport().set_input_as_handled()

const PLAYER_ATTACK_RANGE: int = 1

func _move_player(target_slot: int) -> void:
	if player_actions <= 0 or not _movement_targets(player_slot).has(target_slot):
		status_label.text = "No quedan acciones o esa casilla no es válida."
		return
	player_slot = target_slot
	player_actions -= 1
	movement_preview = false
	attack_preview = false
	status_label.text = "Te moviste. Acción consumida."
	if player_actions <= 0:
		_refresh()
		_enemy_turn()
		return
	_refresh()

func _player_attack() -> void:
	if battle_finished or creature == null or player_actions <= 0:
		return
	if not _can_attack_from(player_slot, creature_slot, PLAYER_ATTACK_RANGE):
		status_label.text = "La criatura está fuera de alcance."
		return
	creature_health = max(0, creature_health - PLAYER_ATTACK)
	player_actions -= 1
	movement_preview = false
	attack_preview = false
	if creature_health <= 0:
		battle_finished = true
		var newly_unlocked: bool = run_progress.unlock_creature_after_adventure_victory(creature.id)
		status_label.text = "¡VICTORIA! Carta desbloqueada: %s." % creature.display_name if newly_unlocked else "¡VICTORIA! %s ya estaba desbloqueada." % creature.display_name
		retry_button.visible = true
		retry_button.text = "VOLVER A AVENTURA"
	else:
		status_label.text = "Ataque realizado. Acción consumida."
		if player_actions <= 0:
			_refresh()
			_enemy_turn()
			return
	_refresh()

func _enemy_turn() -> void:
	movement_preview = false
	attack_preview = false
	var enemy_actions: int = ACTIONS_PER_TURN
	while enemy_actions > 0 and not battle_finished:
		if _can_attack_from(creature_slot, player_slot, max(1, creature.attack_range)):
			player_health = max(0, player_health - max(1, creature.attack))
			enemy_actions -= 1
			status_label.text = "%s te atacó." % creature.display_name
			if player_health <= 0:
				battle_finished = true
				status_label.text = "DERROTA. La criatura sigue sin desbloquearse."
				retry_button.visible = true
				retry_button.text = "REINTENTAR"
				break
		else:
			var next_slot: int = _best_enemy_move()
			if next_slot < 0:
				break
			creature_slot = next_slot
			enemy_actions -= 1
			status_label.text = "%s se acercó." % creature.display_name
	_refresh()
	if not battle_finished:
		turn_number += 1
		player_actions = ACTIONS_PER_TURN
		status_label.text = "Turno %d: tienes %d acciones." % [turn_number, player_actions]
	_refresh()

func _best_enemy_move() -> int:
	var best_slot: int = -1
	var best_distance: int = _distance(creature_slot, player_slot)
	for candidate in _movement_targets(creature_slot, max(1, creature.movement)):
		var distance: int = _distance(candidate, player_slot)
		if distance < best_distance:
			best_distance = distance
			best_slot = candidate
	return best_slot

func _movement_targets(from_slot: int, movement: int = PLAYER_MOVEMENT) -> Array[int]:
	var targets: Array[int] = []
	if from_slot < 0 or from_slot >= CELL_COUNT:
		return targets
	var from_row: int = int(from_slot / BOARD_SIZE)
	var from_column: int = from_slot % BOARD_SIZE
	for candidate in range(CELL_COUNT):
		if candidate == player_slot or candidate == creature_slot:
			continue
		var row: int = int(candidate / BOARD_SIZE)
		var column: int = candidate % BOARD_SIZE
		var distance: int = abs(row - from_row) + abs(column - from_column)
		if distance > 0 and distance <= max(1, movement):
			targets.append(candidate)
	return targets

func _can_attack_from(attacker_slot: int, target_slot: int, attack_range: int) -> bool:
	if attacker_slot < 0 or target_slot < 0:
		return false
	return _distance(attacker_slot, target_slot) <= max(1, attack_range)

func _distance(first_slot: int, second_slot: int) -> int:
	var first_row: int = int(first_slot / BOARD_SIZE)
	var first_column: int = first_slot % BOARD_SIZE
	var second_row: int = int(second_slot / BOARD_SIZE)
	var second_column: int = second_slot % BOARD_SIZE
	return abs(first_row - second_row) + abs(first_column - second_column)

func _refresh() -> void:
	if actions_label != null:
		actions_label.text = "●".repeat(player_actions) + "○".repeat(ACTIONS_PER_TURN - player_actions)
	for index in range(board_buttons.size()):
		var cell: Button = board_buttons[index]
		cell.icon = null
		cell.text = ""
		var is_player: bool = index == player_slot
		var is_creature: bool = index == creature_slot
		var movement_target: bool = movement_preview and player_actions > 0 and _movement_targets(player_slot).has(index)
		var attack_target: bool = attack_preview and is_creature and _can_attack_from(player_slot, creature_slot, PLAYER_ATTACK_RANGE) and player_actions > 0
		var background: Color = Color("#20382E") if (int(index / BOARD_SIZE) + index % BOARD_SIZE) % 2 == 0 else Color("#263D32")
		var border: Color = BORDER
		if movement_target:
			background = Color("#205B49")
			border = GREEN
		if attack_target:
			background = Color("#62531B")
			border = GOLD
		if is_player:
			cell.text = "TÚ"
			background = Color("#174B37")
			border = GREEN
		elif is_creature and creature != null:
			cell.text = creature.display_name
			background = Color("#512B2B")
			border = RED
			var texture: Texture2D = _load_creature_portrait(creature)
			if texture != null:
				cell.icon = texture
		cell.add_theme_stylebox_override("normal", _style(background, border, 2 if is_player or is_creature or movement_target or attack_target else 1))
		cell.add_theme_stylebox_override("hover", _style(background.lightened(0.08), border, 2))
		cell.add_theme_stylebox_override("pressed", _style(background.darkened(0.08), border, 2))
		cell.disabled = battle_finished

func _on_retry_pressed() -> void:
	if player_health <= 0 and creature != null:
		player_health = PLAYER_MAX_HEALTH
		creature_health = max(1, creature.max_health)
		player_slot = PLAYER_START_SLOT
		creature_slot = CREATURE_START_SLOT
		player_actions = ACTIONS_PER_TURN
		turn_number = 1
		battle_finished = false
		movement_preview = false
		attack_preview = false
		retry_button.visible = false
		status_label.text = "Inténtalo de nuevo. Derrota a la criatura para desbloquearla."
		_refresh()
		return
	_return_to_adventure()

func _return_to_adventure() -> void:
	get_tree().change_scene_to_file("res://scenes/adventure.tscn")
