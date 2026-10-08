class_name BattleEngine
extends RefCounted

signal event_emitted(event: BattleEvent)
signal command_resolved(result: BattleResult)
signal state_changed
signal battle_finished(player_won: bool)

var state: BattleState
var _event_sequence: int = 0
var _command_sequence: int = 0
var _active_command_id: String = ""

func setup(
	player_cards: Array[CardDefinition],
	enemy_cards: Array[CardDefinition],
	process_catalog: Array[CardDefinition] = [],
	ium_catalog: Array[CardDefinition] = []
) -> void:
	_reset_connections()
	state = BattleState.new()
	state.setup(player_cards, enemy_cards, process_catalog, ium_catalog)
	state.event_occurred.connect(_on_state_event)
	state.state_changed.connect(_on_state_changed)
	state.battle_finished.connect(_on_state_battle_finished)
	_emit_event(BattleEvent.EventType.TURN_STARTED, "Turno 0: despliegue inicial.", {"turn": 0, "setup_phase": true})

func execute(command: BattleCommand) -> BattleResult:
	if command == null:
		return _reject(BattleResult.error("COMMAND_MISSING", "No existe comando."), "")

	if command.request_id.is_empty():
		command.request_id = _next_command_id()

	_active_command_id = command.request_id
	var validation: BattleResult = BattleValidator.validate(state, command)
	validation.command_id = command.request_id

	if not validation.success:
		return _reject(validation, command.request_id)

	_emit_event(BattleEvent.EventType.COMMAND_ACCEPTED, command.type_name(), {
		"command": command.type_name()
	})

	var resolved: BattleResult = BattleResult.error("NOT_RESOLVED", "Comando no resuelto.")

	match command.type:
		BattleCommand.CommandType.PLAY_CARD:
			resolved = _execute_play_card(command)
		BattleCommand.CommandType.ATTACK:
			resolved = _execute_attack(command)
		BattleCommand.CommandType.HERO_ATTACK:
			resolved = _execute_hero_attack(command)
		BattleCommand.CommandType.MOVE_UNIT:
			resolved = _execute_move(command)
		BattleCommand.CommandType.MIXER_PLACE:
			resolved = _execute_mixer_place(command)
		BattleCommand.CommandType.MIXER_PLACE_CATALOG_IUM:
			resolved = _execute_mixer_catalog_place(command)
		BattleCommand.CommandType.MIXER_REMOVE:
			resolved = _execute_mixer_remove(command)
		BattleCommand.CommandType.MIXER_RESOLVE:
			resolved = state.resolve_mixer()
		BattleCommand.CommandType.END_TURN:
			resolved = _execute_end_turn()
		BattleCommand.CommandType.SURRENDER:
			resolved = BattleResult.error("UNSUPPORTED_COMMAND", "Rendirse aún no está implementado.")

	resolved.command_id = command.request_id

	if resolved.success:
		_emit_event(BattleEvent.EventType.COMMAND_RESOLVED, resolved.message, {
			"command": command.type_name(),
			"result": resolved.code
		})
	else:
		_emit_event(BattleEvent.EventType.COMMAND_REJECTED, resolved.message, {
			"command": command.type_name(),
			"result": resolved.code
		})

	command_resolved.emit(resolved)
	return resolved

func get_state() -> BattleState:
	return state

func debug_snapshot() -> Dictionary:
	if state == null:
		return {"ready": false}
	return {
		"ready": true,
		"turn": state.turn,
		"finished": state.finished,
		"winner_is_player": state.winner_is_player,
		"player_health": state.player_health,
		"enemy_health": state.enemy_health,
		"player_actions": state.player_actions,
		"player_max_actions": state.player_max_actions,
		"player_etherium": state.player_etherium,
		"player_max_etherium": state.player_max_etherium,
		"hand_size": state.hand.size(),
		"deck_size": state.deck.size(),
		"discard_size": state.discard.size(),
		"mixer_inputs": state.mixer.count(),
		"board_cells": BattleBoard.CELL_COUNT,
		"player_board_occupied": state.board.occupied_count(BattleBoard.Owner.PLAYER),
		"enemy_board_occupied": state.board.occupied_count(BattleBoard.Owner.ENEMY),
		"event_sequence": _event_sequence
	}

func _execute_play_card(command: BattleCommand) -> BattleResult:
	var card: CardDefinition = state.hand[command.hand_index]
	var card_name: String = card.display_name
	if not state.play_card(card, command.target_slot, command.target_enemy):
		return BattleResult.error("ENGINE_REJECTED", "BattleState rechazó jugar %s." % card_name)
	_emit_event(BattleEvent.EventType.CARD_PLAYED, card_name, {
		"card": card_name,
		"hand_index": command.hand_index,
		"target_slot": command.target_slot
	})
	return BattleResult.ok("Carta jugada: %s." % card_name)

func _execute_attack(command: BattleCommand) -> BattleResult:
	var attacker: CardDefinition = state.board.get_card(command.attacker_slot)
	var name: String = attacker.display_name if attacker != null else "CRIATURA"
	if not state.attack_unit(command.attacker_slot, command.target_slot):
		return BattleResult.error("ENGINE_REJECTED", "BattleState rechazó el ataque de %s." % name)
	_emit_event(BattleEvent.EventType.ATTACK_RESOLVED, name, {
		"attacker_slot": command.attacker_slot,
		"target_slot": command.target_slot
	})
	return BattleResult.ok("Ataque resuelto: %s." % name)

func _execute_hero_attack(command: BattleCommand) -> BattleResult:
	var name: String = state.player_hero.display_name if state.player_hero != null else "REY"
	if not state.hero_attack(command.attacker_slot, command.direction):
		return BattleResult.error("ENGINE_REJECTED", "BattleState rechazó el ataque del Rey.")
	_emit_event(BattleEvent.EventType.ATTACK_RESOLVED, name, {
		"attacker_slot": command.attacker_slot,
		"attack_direction": {
			"x": command.direction.x,
			"y": command.direction.y
		}
	})
	return BattleResult.ok("El Rey atacó las 3 casillas frontales.")

func _execute_move(command: BattleCommand) -> BattleResult:
	var unit: CardDefinition = state.board.get_card(command.attacker_slot)
	var name: String = unit.display_name if unit != null else "CRIATURA"
	if not state.move_unit(command.attacker_slot, command.target_slot):
		return BattleResult.error("ENGINE_REJECTED", "BattleState rechazó mover %s." % name)
	return BattleResult.ok("Movimiento resuelto: %s." % name)

func _execute_mixer_place(command: BattleCommand) -> BattleResult:
	var card: CardDefinition = state.hand[command.hand_index]
	var name: String = card.display_name
	if not state.place_ium_in_mixer(command.hand_index, command.mixer_slot):
		return BattleResult.error("ENGINE_REJECTED", "No se pudo colocar %s." % name)
	return BattleResult.ok("%s colocado en el mezclador." % name)

func _execute_mixer_catalog_place(command: BattleCommand) -> BattleResult:
	var card: CardDefinition = state.ium_catalog[command.catalog_index]
	if not state.place_catalog_ium_in_mixer(command.catalog_index, command.mixer_slot):
		return BattleResult.error("ENGINE_REJECTED", "No se pudo colocar %s." % card.display_name)
	return BattleResult.ok("%s colocado en el mezclador." % card.display_name)

func _execute_mixer_remove(command: BattleCommand) -> BattleResult:
	if not state.remove_ium_from_mixer(command.mixer_slot):
		return BattleResult.error("ENGINE_REJECTED", "No se pudo devolver el IUM.")
	return BattleResult.ok("IUM retirado del mezclador.")

func _execute_end_turn() -> BattleResult:
	var previous_turn: int = state.turn
	state.end_turn()
	if state.is_finished():
		return BattleResult.ok("El turno %d terminó la batalla." % previous_turn)
	_emit_event(BattleEvent.EventType.TURN_ENDED, "Turno %d terminado." % previous_turn, {"turn": previous_turn})
	_emit_event(BattleEvent.EventType.TURN_STARTED, "Turno %d iniciado." % state.turn, {"turn": state.turn})
	return BattleResult.ok("Turno %d terminado." % previous_turn)

func _reject(result: BattleResult, command_id: String) -> BattleResult:
	result.command_id = command_id
	_emit_event(BattleEvent.EventType.COMMAND_REJECTED, result.message, {
		"code": result.code,
		"command": command_id
	})
	command_resolved.emit(result)
	return result

func _on_state_event(message: String) -> void:
	_emit_event(BattleEvent.EventType.DIAGNOSTIC, message)

func _on_state_changed() -> void:
	_emit_event(BattleEvent.EventType.STATE_CHANGED, "Estado actualizado.", debug_snapshot())
	state_changed.emit()

func _on_state_battle_finished(player_won: bool) -> void:
	_emit_event(BattleEvent.EventType.BATTLE_FINISHED, "VICTORIA" if player_won else "DERROTA", {"player_won": player_won})
	battle_finished.emit(player_won)

func _emit_event(event_type: int, message: String, data: Dictionary = {}) -> BattleEvent:
	_event_sequence += 1
	var event: BattleEvent = BattleEvent.create(event_type, message, data)
	event.sequence = _event_sequence
	event.command_id = _active_command_id
	event_emitted.emit(event)
	_record_diagnostic(event)
	return event

func _record_diagnostic(event: BattleEvent) -> void:
	var main_loop: MainLoop = Engine.get_main_loop()
	if not main_loop is SceneTree:
		return
	var scene_tree: SceneTree = main_loop
	var diagnostics: Node = scene_tree.root.get_node_or_null("GarliaDiagnostics")
	if diagnostics == null:
		return
	var level: String = "ERROR" if event.type == BattleEvent.EventType.COMMAND_REJECTED else "INFO"
	diagnostics.call("write_entry", level, "BATTLE_ENGINE", event.type_name(), event.message, event.data)

func _next_command_id() -> String:
	_command_sequence += 1
	return "CMD-%04d" % _command_sequence

func _reset_connections() -> void:
	if state == null:
		return
	if state.event_occurred.is_connected(_on_state_event):
		state.event_occurred.disconnect(_on_state_event)
	if state.state_changed.is_connected(_on_state_changed):
		state.state_changed.disconnect(_on_state_changed)
	if state.battle_finished.is_connected(_on_state_battle_finished):
		state.battle_finished.disconnect(_on_state_battle_finished)
