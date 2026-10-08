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

	var playable_index: int = -1
	for index in range(state.hand.size()):
		var card: CardDefinition = state.hand[index]
		if card != null and card.is_unit() and card.cost <= state.player_etherium:
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
		_report(report, "move_costs_etherium", state.player_etherium == previous_etherium - BattleState.MOVE_ETHERIUM_COST)

	_report(report, "execute_move_unit", moved)
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
