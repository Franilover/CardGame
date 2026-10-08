class_name BattleSmokeTest
extends RefCounted

static func run() -> Dictionary:
	var report: Dictionary = {
		"passed": false,
		"steps": [],
		"errors": []
	}

	var player_cards: Array[CardDefinition] = CardCatalog.starter_deck()
	var enemy_cards: Array[CardDefinition] = CardCatalog.enemy_deck()
	var engine := BattleEngine.new()
	engine.setup(player_cards, enemy_cards, [])
	_report(report, "setup", engine.get_state() != null)

	var state: BattleState = engine.get_state()
	if state == null:
		report["errors"].append("BattleState no fue creado.")
		return report

	_report(report, "board_9x8", state.board.occupants.size() == BattleBoard.CELL_COUNT)
	_report(report, "player_hero_on_trone", state.board.get_card(BattleBoard.PLAYER_HERO_SLOT) == state.player_hero)
	_report(report, "enemy_hero_on_trone", state.board.get_card(BattleBoard.ENEMY_HERO_SLOT) == state.enemy_hero)
	_report(report, "hero_attack_has_three_front_cells", state.board.front_attack_indices(state.player_hero_slot, Vector2i.UP).size() == 3)
	_report(report, "hero_attack_has_four_direction_model", Vector2i.UP != Vector2i.DOWN and Vector2i.LEFT != Vector2i.RIGHT)

	var playable_index: int = -1
	for index in range(state.hand.size()):
		var card: CardDefinition = state.hand[index]
		if card != null and card.is_unit() :
			playable_index = index
			break

	_report(report, "find_playable_unit", playable_index >= 0)

	if playable_index >= 0:
		var spawn_slot: int = BattleBoard.index_from_position_static(Vector2i(3, 7))
		var result: BattleResult = engine.execute(BattleCommand.play_card(playable_index, spawn_slot, false))
		_report(report, "execute_play_card", result.success, result.describe())

	var end_result: BattleResult = engine.execute(BattleCommand.end_turn())
	_report(report, "execute_end_turn", end_result.success, end_result.describe())

	var moved: bool = false
	var moved_again: bool = false
	var player_unit_slot: int = -1
	for candidate_slot in state.board.indices_for_owner(BattleBoard.Owner.PLAYER):
		if candidate_slot != state.player_hero_slot:
			player_unit_slot = candidate_slot
			break
	if player_unit_slot >= 0:
		var origin: Vector2i = state.board.position_from_index(player_unit_slot)
		var target: int = BattleBoard.index_from_position_static(Vector2i(origin.x, max(BattleBoard.PLAYER_ZONE_MIN_ROW, origin.y - 1)))
		var previous_actions: int = state.player_actions
		var previous_etherium: int = state.player_etherium
		var move_result: BattleResult = engine.execute(BattleCommand.move_unit(player_unit_slot, target))
		moved = move_result.success
		_report(report, "move_keeps_actions", state.player_actions == previous_actions)
		_report(report, "move_does_not_cost_etherium", state.player_etherium == previous_etherium)

		var second_origin: int = target
		var second_position: Vector2i = state.board.position_from_index(second_origin)
		var second_target: int = BattleBoard.index_from_position_static(Vector2i(second_position.x, max(BattleBoard.PLAYER_ZONE_MIN_ROW, second_position.y - 1)))
		var second_previous_etherium: int = state.player_etherium
		var second_result: BattleResult = engine.execute(BattleCommand.move_unit(second_origin, second_target))
		moved_again = second_result.success
		_report(report, "same_unit_cannot_move_again", not moved_again and second_result.code == "UNIT_ALREADY_MOVED", second_result.describe())
		_report(report, "blocked_second_move_keeps_etherium", state.player_etherium == second_previous_etherium)

	_report(report, "execute_move_unit", moved)
	_report(report, "execute_second_move_same_unit", not moved_again)

	var hero_moved: bool = false
	var hero_origin: int = state.player_hero_slot
	var hero_target: int = BattleBoard.index_from_position_static(Vector2i(4, 6))
	var hero_previous_etherium: int = state.player_etherium
	var hero_move_result: BattleResult = engine.execute(BattleCommand.move_unit(hero_origin, hero_target))
	hero_moved = hero_move_result.success
	_report(report, "move_hero", hero_moved, hero_move_result.describe())
	_report(report, "hero_move_does_not_cost_etherium", state.player_etherium == hero_previous_etherium)
	_report(report, "hero_left_throne", state.board.get_card(BattleBoard.PLAYER_HERO_SLOT) == null)
	var hero_return_result: BattleResult = engine.execute(BattleCommand.move_unit(hero_target, BattleBoard.PLAYER_HERO_SLOT))
	_report(report, "hero_cannot_move_twice_same_turn", not hero_return_result.success and hero_return_result.code == "UNIT_ALREADY_MOVED", hero_return_result.describe())
	_report(report, "hero_can_return_to_throne", state.board.can_move(hero_target, BattleBoard.PLAYER_HERO_SLOT, BattleBoard.Owner.PLAYER, state.player_hero.movement))

	var previous_actions_before_hero_attack: int = state.player_actions
	var hero_attack_result: BattleResult = engine.execute(BattleCommand.hero_attack(hero_target, Vector2i.UP))
	_report(report, "hero_attack_command", hero_attack_result.success, hero_attack_result.describe())
	_report(report, "hero_attack_costs_action", state.player_actions == previous_actions_before_hero_attack - 1)
	_report(report, "one_attack_remaining", state.player_attacks_remaining == state.player_max_attacks_per_turn - 1)

	var second_attack_result: BattleResult = engine.execute(BattleCommand.hero_attack(hero_target, Vector2i.UP))
	_report(report, "second_attack_rejected_same_turn", not second_attack_result.success and second_attack_result.code == "NO_ATTACKS_REMAINING", second_attack_result.describe())

	var actions_before_turn: int = state.player_actions
	var etherium_before_turn: int = state.player_max_etherium
	var end_again_result: BattleResult = engine.execute(BattleCommand.end_turn())
	_report(report, "next_turn_starts", end_again_result.success)
	_report(report, "actions_reset_to_two", state.player_actions == state.player_max_actions)
	_report(report, "actions_remain_fixed", state.player_max_actions == BattleState.ACTIONS_PER_TURN)
	_report(report, "attack_resets_next_turn", state.player_attacks_remaining == state.player_max_attacks_per_turn)
	_report(report, "etherium_grows_next_turn", state.player_max_etherium == min(BattleState.MAX_ETHERIUM, etherium_before_turn + BattleState.ETHERIUM_GROWTH_PER_TURN))
	report["snapshot"] = engine.debug_snapshot()

	var all_steps_passed: bool = true
	for step in report["steps"]:
		var step_data: Dictionary = step
		if not bool(step_data.get("passed", false)):
			all_steps_passed = false
			break

	report["passed"] = report["errors"].is_empty() and all_steps_passed
	return report

static func _report(report: Dictionary, step_name: String, passed: bool, detail: String = "") -> void:
	report["steps"].append({
		"name": step_name,
		"passed": passed,
		"detail": detail
	})
	if not passed:
		report["errors"].append("%s: %s" % [step_name, detail])
