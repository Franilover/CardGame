extends Node

var state: BattleState
var selected_card: CardDefinition
var hand_buttons: Array[Button] = []
var slot_buttons: Array[Button] = []
var status_label: Label
var enemy_label: Label
var player_label: Label
var etherium_label: Label
var turn_label: Label
var log_label: RichTextLabel
var end_turn_button: Button

func _ready() -> void:
	_build_ui()
	_start_battle()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title := Label.new()
	title.text = "GARLIA — CARDGAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var info := HBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(info)

	turn_label = Label.new()
	player_label = Label.new()
	enemy_label = Label.new()
	etherium_label = Label.new()
	for label in [turn_label, player_label, enemy_label, etherium_label]:
		info.add_child(label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(status_label)

	var enemy_title := Label.new()
	enemy_title.text = "ENEMIGO"
	enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(enemy_title)

	var enemy_slots := HBoxContainer.new()
	enemy_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(enemy_slots)
	for i in range(BattleState.ENEMY_SLOTS):
		var slot := Label.new()
		slot.text = "[ Vacío ]"
		slot.custom_minimum_size = Vector2(180, 90)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		enemy_slots.add_child(slot)

	var player_title := Label.new()
	player_title.text = "TU CAMPO — selecciona una carta y luego una posición"
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(player_title)

	var player_slots := HBoxContainer.new()
	player_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(player_slots)
	for i in range(BattleState.PLAYER_SLOTS):
		var slot := Button.new()
		slot.text = "[ Vacío ]"
		slot.custom_minimum_size = Vector2(180, 110)
		slot.pressed.connect(_on_slot_pressed.bind(i))
		player_slots.add_child(slot)
		slot_buttons.append(slot)

	var hand_title := Label.new()
	hand_title.text = "MANO"
	hand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hand_title)

	var hand := HBoxContainer.new()
	hand.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(hand)
	for i in range(8):
		var button := Button.new()
		button.custom_minimum_size = Vector2(130, 100)
		button.pressed.connect(_on_hand_pressed.bind(i))
		hand.add_child(button)
		hand_buttons.append(button)

	end_turn_button = Button.new()
	end_turn_button.text = "TERMINAR TURNO [Espacio]"
	end_turn_button.custom_minimum_size = Vector2(240, 48)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	root.add_child(end_turn_button)

	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 100)
	root.add_child(log_label)

func _start_battle() -> void:
	state = BattleState.new()
	state.reset()
	state.deck = CardCatalog.starter_deck()

	var enemies := CardCatalog.enemy_deck()
	for i in range(min(enemies.size(), BattleState.ENEMY_SLOTS)):
		state.enemy_board.append(enemies[i])

	for i in range(5):
		state.draw_card()

	state.state_changed.connect(_refresh)
	_refresh()

func _on_hand_pressed(index: int) -> void:
	if index >= state.hand.size():
		return
	selected_card = state.hand[index]
	status_label.text = "Seleccionada: %s — %s" % [selected_card.display_name, selected_card.description]
	_refresh()

func _on_slot_pressed(index: int) -> void:
	if selected_card == null:
		status_label.text = "Selecciona una carta de la mano."
		return

	if selected_card.is_unit():
		if state.play_card(selected_card, index):
			_log("Jugaste %s en la posición %d." % [selected_card.display_name, index + 1])
			selected_card = null
		else:
			status_label.text = "No puedes jugar esa carta ahí."
	else:
		if state.play_card(selected_card):
			_log("Ejecutaste %s." % selected_card.display_name)
			selected_card = null

	_refresh()

func _on_end_turn_pressed() -> void:
	if state.is_finished():
		return

	_log("Turno %d terminado." % state.turn)
	state.end_turn()

	if state.is_finished():
		status_label.text = "VICTORIA" if state.player_won() else "DERROTA"
		end_turn_button.disabled = true

	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		_on_end_turn_pressed()

func _refresh() -> void:
	if state == null:
		return

	turn_label.text = "Turno: %d" % state.turn
	player_label.text = "  Vida: %d  " % state.player_health
	enemy_label.text = "  Enemigo: %d  " % state.enemy_health
	etherium_label.text = "  Eterium: %d/%d  " % [state.player_etherium, state.player_max_etherium]

	for i in range(hand_buttons.size()):
		var button := hand_buttons[i]
		if i < state.hand.size():
			var card: CardDefinition = state.hand[i]
			button.text = "%s\n[%s] Costo %d\n%s" % [card.display_name, card.type_name(), card.cost, card.description]
			button.disabled = card.cost > state.player_etherium
		else:
			button.text = ""
			button.disabled = true

	for i in range(slot_buttons.size()):
		if i < state.player_board.size() and state.player_board[i] != null:
			var card: CardDefinition = state.player_board[i]
			slot_buttons[i].text = "%s\nATQ %d / VIDA %d" % [card.display_name, card.attack, card.health]
		else:
			slot_buttons[i].text = "[ Vacío ]"

func _log(message: String) -> void:
	log_label.append_text(message + "\n")
