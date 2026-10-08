class_name BattleValidator
extends RefCounted

## Valida comandos de entrada.
## No modifica el estado.

static func validate(state: BattleState, command: BattleCommand) -> BattleResult:
	if state == null:
		return BattleResult.error("STATE_MISSING", "No existe BattleState.")
	if command == null:
		return BattleResult.error("COMMAND_MISSING", "No existe comando.")
	if state.is_finished():
		return BattleResult.error("BATTLE_FINISHED", "La batalla ya terminó.")

	match command.type:
		BattleCommand.CommandType.PLAY_CARD:
			return _validate_play_card(state, command)
		BattleCommand.CommandType.ATTACK:
			return _validate_attack(state, command)
		BattleCommand.CommandType.END_TURN:
			return _validate_end_turn(state)
		BattleCommand.CommandType.SURRENDER:
			return BattleResult.error("UNSUPPORTED_COMMAND", "Rendirse aún no forma parte del motor v0.1.")

	return BattleResult.error("UNKNOWN_COMMAND", "Tipo de comando desconocido.")

static func _validate_play_card(state: BattleState, command: BattleCommand) -> BattleResult:
	if command.hand_index < 0 or command.hand_index >= state.hand.size():
		return BattleResult.error("HAND_INDEX_INVALID", "La carta seleccionada no existe en la mano.")

	var card: CardDefinition = state.hand[command.hand_index]
	if not state.can_play(card):
		return BattleResult.error("CARD_NOT_PLAYABLE", "La carta no puede jugarse ahora.")

	if card.is_unit():
		if command.target_enemy:
			return BattleResult.error("UNIT_TARGET_INVALID", "Una criatura del jugador solo puede entrar a su tablero.")
		if command.target_slot < 0 or command.target_slot >= BattleState.PLAYER_SLOTS:
			return BattleResult.error("SLOT_INVALID", "La casilla objetivo no es válida.")
		if state.player_board[command.target_slot] != null:
			return BattleResult.error("SLOT_OCCUPIED", "La casilla objetivo ya está ocupada.")

	return BattleResult.ok()

static func _validate_attack(state: BattleState, command: BattleCommand) -> BattleResult:
	if command.attacker_slot < 0 or command.attacker_slot >= BattleState.PLAYER_SLOTS:
		return BattleResult.error("ATTACKER_SLOT_INVALID", "La casilla del atacante no es válida.")
	if command.target_slot < -1 or command.target_slot >= BattleState.ENEMY_SLOTS:
		return BattleResult.error("TARGET_SLOT_INVALID", "La casilla objetivo no es válida.")

	var attacker: CardDefinition = state.player_board[command.attacker_slot]
	if attacker == null:
		return BattleResult.error("ATTACKER_MISSING", "No existe criatura en la casilla del atacante.")
	if not attacker.can_attack():
		return BattleResult.error("ATTACK_NOT_ALLOWED", "La criatura no puede atacar ahora.")

	return BattleResult.ok()

static func _validate_end_turn(_state: BattleState) -> BattleResult:
	return BattleResult.ok()