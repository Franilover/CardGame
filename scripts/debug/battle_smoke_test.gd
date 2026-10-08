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

	var playable_index: int = -1
	for index in range(state.hand.size()):
		var card: CardDefinition = state.hand[index]
		if card != null and card.is_unit() and card.cost <= state.player_etherium:
			playable_index = index
			break

	_report(report, "find_playable_unit", playable_index >= 0)

	if playable_index >= 0:
		var spawn_slot: int = BattleBoard.index_from_position_static(Vector2i(4, 7))
		var result: BattleResult = engine.execute(BattleCommand.play_card(playable_index, spawn_slot, false))
		_report(report, "execute_play_card", result.success, result.describe())

	var end_result: BattleResult = engine.execute(BattleCommand.end_turn())
	_report(report, "execute_end_turn", end_result.success, end_result.describe())

	var moved: bool = false
	var player_unit_slot: int = state.board.first_index_for_owner(BattleBoard.Owner.PLAYER)
	if player_unit_slot >= 0:
		var origin: Vector2i = state.board.position_from_index(player_unit_slot)
		var target: int = BattleBoard.index_from_position_static(Vector2i(origin.x, max(5, origin.y - 1)))
		var move_result: BattleResult = engine.execute(BattleCommand.move_unit(player_unit_slot, target))
		moved = move_result.success

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
