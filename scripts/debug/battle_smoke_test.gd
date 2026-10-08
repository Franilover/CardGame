class_name BattleSmokeTest
extends RefCounted

## Smoke test de FASE 00.
## Verifica que Command -> Engine -> State mantenga un camino funcional.

static func run() -> Dictionary:
	var report: Dictionary = {
		"passed": false,
		"steps": [],
		"errors": []
	}

	var player_cards: Array[CardDefinition] = CardCatalog.starter_deck()
	var enemy_cards: Array[CardDefinition] = CardCatalog.enemy_deck()
	var engine := BattleEngine.new()

	engine.setup(player_cards, enemy_cards)
	_report(report, "setup", engine.get_state() != null)

	var state: BattleState = engine.get_state()
	if state == null:
		report["errors"].append("BattleState no fue creado.")
		return report

	var playable_index: int = -1

	for index in range(state.hand.size()):
		var card: CardDefinition = state.hand[index]
		if card != null and card.cost <= state.player_etherium:
			playable_index = index
			break

	_report(report, "find_playable_card", playable_index >= 0)

	if playable_index >= 0:
		var hand_card: CardDefinition = state.hand[playable_index]
		var command: BattleCommand

		if hand_card.is_unit():
			command = BattleCommand.play_card(playable_index, 0, false)
		else:
			command = BattleCommand.play_card(playable_index, -1, false)

		var result: BattleResult = engine.execute(command)
		_report(report, "execute_play_card", result.success, result.describe())
	else:
		report["errors"].append("La mano inicial no contiene una carta jugable para el smoke test.")

	var end_result: BattleResult = engine.execute(BattleCommand.end_turn())
	_report(report, "execute_end_turn", end_result.success, end_result.describe())

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