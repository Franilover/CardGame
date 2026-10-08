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

	var state: BattleState = engine.get_state()
	_report(report, "setup", state != null)
	if state == null:
		report["errors"].append("BattleState no fue creado.")
		return report

	_report(report, "board_9x8", state.board.occupants.size() == BattleBoard.CELL_COUNT)
	_report(report, "player_hero_on_trone", state.board.get_card(BattleBoard.PLAYER_HERO_SLOT) == state.player_hero)
	_report(report, "enemy_hero_on_trone", state.board.get_card(BattleBoard.ENEMY_HERO_SLOT) == state.enemy_hero)
	_report(report, "two_actions_start", state.player_actions == 2)

	var creature := _make_test_creature("Criatura de prueba")
	state.hand.append(creature)

	var back_row_slot: int = BattleBoard.index_from_position_static(Vector2i(3, 7))
	var etherium_before_free_deploy: int = state.player_etherium
	var actions_before_free_deploy: int = state.player_actions
	var free_deploy_result: BattleResult = engine.execute(BattleCommand.play_card(state.hand.size() - 1, back_row_slot, false))
	_report(report, "creature_deploys_in_back_row", free_deploy_result.success, free_deploy_result.describe())
	_report(report, "back_row_deploy_spends_one_action", state.player_actions == actions_before_free_deploy - 1)
	_report(report, "back_row_deploy_is_free", state.player_etherium == etherium_before_free_deploy)

	var first_origin: int = back_row_slot
	var first_target: int = BattleBoard.index_from_position_static(Vector2i(3, 6))
	var etherium_before_move: int = state.player_etherium
	var actions_before_move: int = state.player_actions
	var move_result: BattleResult = engine.execute(BattleCommand.move_unit(first_origin, first_target))
	_report(report, "move_uses_one_action", move_result.success and state.player_actions == actions_before_move - 1, move_result.describe())
	_report(report, "move_does_not_cost_etherium", state.player_etherium == etherium_before_move)

	var blocked_move_result: BattleResult = engine.execute(BattleCommand.move_unit(first_target, back_row_slot))
	_report(report, "no_actions_blocks_third_action", not blocked_move_result.success and blocked_move_result.code == "NO_ACTIONS", blocked_move_result.describe())

	var turn_end_result: BattleResult = engine.execute(BattleCommand.end_turn())
	_report(report, "end_turn", turn_end_result.success, turn_end_result.describe())
	_report(report, "actions_reset", state.player_actions == state.player_max_actions)
	_report(report, "actions_are_two", state.player_max_actions == BattleState.ACTIONS_PER_TURN)

	var etherium_before_growth: int = state.player_max_etherium
	_report(report, "etherium_grows", state.player_max_etherium == min(BattleState.MAX_ETHERIUM, etherium_before_growth))

	var advanced_creature := _make_test_creature("Despliegue adelantado")
	state.hand.append(advanced_creature)
	var advanced_slot: int = BattleBoard.index_from_position_static(Vector2i(4, 6))
	var etherium_before_advanced: int = state.player_etherium
	var actions_before_advanced: int = state.player_actions
	var advanced_result: BattleResult = engine.execute(BattleCommand.play_card(state.hand.size() - 1, advanced_slot, false))
	_report(report, "advanced_deploy_succeeds", advanced_result.success, advanced_result.describe())
	_report(report, "advanced_deploy_uses_action", state.player_actions == actions_before_advanced - 1)
	_report(report, "advanced_deploy_costs_etherium", state.player_etherium == etherium_before_advanced - BattleState.ADVANCED_DEPLOYMENT_ETHERIUM_COST)

	state.player_actions = state.player_max_actions
	var attack_creature := _make_test_creature("Atacante de prueba")
	attack_creature.attack_range = 4
	var attack_slot: int = BattleBoard.index_from_position_static(Vector2i(2, 5))
	state.hand.append(attack_creature)
	var attack_deploy_result: BattleResult = engine.execute(BattleCommand.play_card(state.hand.size() - 1, attack_slot, false))
	_report(report, "attack_unit_deployed", attack_deploy_result.success, attack_deploy_result.describe())

	var enemy_test := _make_test_creature("Enemigo de prueba")
	enemy_test.counter_attack = false
	var enemy_slot: int = BattleBoard.index_from_position_static(Vector2i(2, 2))
	var enemy_placed: bool = state.board.place(enemy_slot, enemy_test, BattleBoard.Owner.ENEMY)
	_report(report, "enemy_test_placed", enemy_placed)

	var actions_before_move_and_attack: int = state.player_actions
	var move_for_attack_result: BattleResult = engine.execute(BattleCommand.move_unit(attack_slot, BattleBoard.index_from_position_static(Vector2i(2, 4))))
	_report(report, "move_then_attack_first_action", move_for_attack_result.success, move_for_attack_result.describe())
	var actions_before_attack: int = state.player_actions
	var attack_result: BattleResult = engine.execute(BattleCommand.attack(BattleBoard.index_from_position_static(Vector2i(2, 4)), enemy_slot))
	_report(report, "attack_after_move_is_allowed", attack_result.success, attack_result.describe())
	_report(report, "move_and_attack_use_two_actions", state.player_actions == actions_before_move_and_attack - 2)
	_report(report, "attack_uses_one_action", state.player_actions == actions_before_attack - 1)

	report["snapshot"] = engine.debug_snapshot()

	var all_steps_passed: bool = true
	for step in report["steps"]:
		var step_data: Dictionary = step
		if not bool(step_data.get("passed", false)):
			all_steps_passed = false
			break

	report["passed"] = report["errors"].is_empty() and all_steps_passed
	return report

static func _make_test_creature(name: String) -> CardDefinition:
	var card := CardDefinition.new()
	card.id = name.to_lower().replace(" ", "_")
	card.display_name = name
	card.card_type = CardDefinition.CardType.CREATURE
	card.health = 10
	card.attack = 2
	card.movement = 1
	card.attack_range = 1
	card.counter_attack = true
	return card

static func _report(report: Dictionary, step_name: String, passed: bool, detail: String = "") -> void:
	report["steps"].append({
		"name": step_name,
		"passed": passed,
		"detail": detail
	})
	if not passed:
		report["errors"].append("%s: %s" % [step_name, detail])
