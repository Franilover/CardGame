class_name BattleValidator
extends RefCounted

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
		BattleCommand.CommandType.HERO_ATTACK:
			return _validate_hero_attack(state, command)
		BattleCommand.CommandType.MOVE_UNIT:
			return _validate_move(state, command)
		BattleCommand.CommandType.MIXER_PLACE:
			return _validate_mixer_place(state, command)
		BattleCommand.CommandType.MIXER_REMOVE:
			return _validate_mixer_remove(state, command)
		BattleCommand.CommandType.MIXER_RESOLVE:
			return _validate_mixer_resolve(state)
		BattleCommand.CommandType.END_TURN:
			return BattleResult.ok()
		BattleCommand.CommandType.SURRENDER:
			return BattleResult.error("UNSUPPORTED_COMMAND", "Rendirse aún no está implementado.")

	return BattleResult.error("UNKNOWN_COMMAND", "Tipo de comando desconocido.")

static func _validate_play_card(state: BattleState, command: BattleCommand) -> BattleResult:
	if command.hand_index < 0 or command.hand_index >= state.hand.size():
		return BattleResult.error("HAND_INDEX_INVALID", "La carta seleccionada no existe en la mano.")

	var card: CardDefinition = state.hand[command.hand_index]
	if card == null or not state.can_play(card):
		return BattleResult.error("CARD_NOT_PLAYABLE", "La carta no puede jugarse ahora.")

	if card.is_unit():
		if not state.board.can_place(command.target_slot, BattleBoard.Owner.PLAYER):
			return BattleResult.error("UNIT_SLOT_INVALID", "La casilla no pertenece a la zona inicial del jugador.")
		return BattleResult.ok()

	match card.effect_kind:
		"buff":
			if command.target_enemy or state.board.get_owner(command.target_slot) != BattleBoard.Owner.PLAYER or state.board.get_card(command.target_slot) == null:
				return BattleResult.error("BUFF_TARGET_INVALID", "No hay una unidad aliada en esa casilla.")
		"damage":
			if not command.target_enemy or state.board.get_owner(command.target_slot) != BattleBoard.Owner.ENEMY or state.board.get_card(command.target_slot) == null:
				return BattleResult.error("DAMAGE_TARGET_INVALID", "No hay un enemigo en esa casilla.")
		"damage_all", "draw":
			pass
		_:
			return BattleResult.error("EFFECT_UNSUPPORTED", "La carta aún no tiene un resolver compatible.")

	return BattleResult.ok()

static func _validate_attack(state: BattleState, command: BattleCommand) -> BattleResult:
	if command.attacker_slot < 0 or command.attacker_slot >= BattleBoard.CELL_COUNT:
		return BattleResult.error("ATTACKER_SLOT_INVALID", "El atacante no es válido.")
	var attacker: CardDefinition = state.board.get_card(command.attacker_slot)
	if state.board.get_owner(command.attacker_slot) != BattleBoard.Owner.PLAYER or attacker == null:
		return BattleResult.error("ATTACKER_MISSING", "No existe una unidad aliada.")
	if state.player_attacks_remaining <= 0:
		return BattleResult.error("NO_ATTACKS_REMAINING", "Ya realizaste tu ataque de este turno.")
	if not attacker.can_attack():
		return BattleResult.error("ATTACK_NOT_ALLOWED", "La unidad no puede atacar.")

	if command.target_slot < 0 or command.target_slot >= BattleBoard.CELL_COUNT:
		return BattleResult.error("TARGET_SLOT_INVALID", "El objetivo debe ser una casilla enemiga.")

	var defender: CardDefinition = state.board.get_card(command.target_slot)
	if state.board.get_owner(command.target_slot) != BattleBoard.Owner.ENEMY or defender == null:
		return BattleResult.error("TARGET_NOT_ENEMY", "El objetivo no es enemigo.")
	if state.board.distance(command.attacker_slot, command.target_slot) > max(1, attacker.attack_range):
		return BattleResult.error("TARGET_OUT_OF_RANGE", "El objetivo está fuera de alcance.")

	return BattleResult.ok()

static func _validate_hero_attack(state: BattleState, command: BattleCommand) -> BattleResult:
	if command.attacker_slot != state.player_hero_slot:
		return BattleResult.error("HERO_ATTACKER_INVALID", "Solo el Rey puede usar este ataque.")
	if state.player_actions <= 0:
		return BattleResult.error("NO_ACTIONS", "No quedan acciones.")
	if state.player_attacks_remaining <= 0:
		return BattleResult.error("NO_ATTACKS_REMAINING", "Ya realizaste tu ataque de este turno.")
	var hero: CardDefinition = state.player_hero
	if hero == null or not hero.can_attack():
		return BattleResult.error("HERO_ATTACK_NOT_ALLOWED", "El Rey no puede atacar ahora.")
	if abs(command.direction.x) + abs(command.direction.y) != 1:
		return BattleResult.error("HERO_DIRECTION_INVALID", "El ataque necesita una de las cuatro direcciones.")
	if state.board.front_attack_indices(command.attacker_slot, command.direction).is_empty():
		return BattleResult.error("HERO_ATTACK_OUT_OF_BOARD", "Ese lado queda fuera del tablero.")
	return BattleResult.ok()

static func _validate_move(state: BattleState, command: BattleCommand) -> BattleResult:
	if command.attacker_slot < 0 or command.attacker_slot >= BattleBoard.CELL_COUNT:
		return BattleResult.error("ORIGIN_INVALID", "El origen no es válido.")
	if command.target_slot < 0 or command.target_slot >= BattleBoard.CELL_COUNT:
		return BattleResult.error("DESTINATION_INVALID", "El destino no es válido.")

	var unit: CardDefinition = state.board.get_card(command.attacker_slot)
	if state.board.get_owner(command.attacker_slot) != BattleBoard.Owner.PLAYER or unit == null:
		return BattleResult.error("UNIT_MISSING", "No existe una unidad aliada.")
	if not unit.is_unit():
		return BattleResult.error("UNIT_CANNOT_MOVE", "El objetivo no es una unidad movible.")
	if unit.has_moved:
		return BattleResult.error("UNIT_ALREADY_MOVED", "Esta unidad ya se movió este turno.")
	if not state.board.can_move(command.attacker_slot, command.target_slot, BattleBoard.Owner.PLAYER, unit.movement):
		return BattleResult.error("MOVE_INVALID", "Destino bloqueado, ocupado o fuera de movimiento.")
	return BattleResult.ok()

static func _validate_mixer_place(state: BattleState, command: BattleCommand) -> BattleResult:
	if command.hand_index < 0 or command.hand_index >= state.hand.size():
		return BattleResult.error("HAND_INDEX_INVALID", "La carta no existe.")
	if command.mixer_slot < 0 or command.mixer_slot >= MixerState.SIZE:
		return BattleResult.error("MIXER_SLOT_INVALID", "La casilla del mezclador no es válida.")
	var card: CardDefinition = state.hand[command.hand_index]
	if card == null or card.card_type != CardDefinition.CardType.IUM:
		return BattleResult.error("MIXER_REQUIRES_IUM", "Solo se pueden colocar IUMs.")
	if not state.mixer.is_empty(command.mixer_slot):
		return BattleResult.error("MIXER_SLOT_OCCUPIED", "La casilla ya está ocupada.")
	return BattleResult.ok()

static func _validate_mixer_remove(state: BattleState, command: BattleCommand) -> BattleResult:
	if command.mixer_slot < 0 or command.mixer_slot >= MixerState.SIZE:
		return BattleResult.error("MIXER_SLOT_INVALID", "La casilla no es válida.")
	if state.mixer.is_empty(command.mixer_slot):
		return BattleResult.error("MIXER_SLOT_EMPTY", "La casilla está vacía.")
	if state.hand.size() >= BattleState.MAX_HAND:
		return BattleResult.error("HAND_FULL", "La mano está llena.")
	return BattleResult.ok()

static func _validate_mixer_resolve(state: BattleState) -> BattleResult:
	if state.player_actions <= 0:
		return BattleResult.error("NO_ACTIONS", "No quedan acciones.")
	if state.player_etherium <= 0:
		return BattleResult.error("NO_ETHERIUM", "No tienes Eterium suficiente.")
	if state.mixer.count() < 2:
		return BattleResult.error("MIXER_NEEDS_INPUTS", "Se necesitan al menos dos IUMs.")
	if state.hand.size() >= BattleState.MAX_HAND:
		return BattleResult.error("HAND_FULL", "La mano está llena.")
	return BattleResult.ok()
