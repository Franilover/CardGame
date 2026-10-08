extends SceneTree

## Ejecución headless para CI/local.
## Comando:
## godot --headless --path . --script res://scripts/debug/battle_smoke_test_runner.gd

func _init() -> void:
	var report: Dictionary = BattleSmokeTest.run()

	print("=== GARLIA CARDGAME / BATTLE SMOKE TEST ===")
	print(JSON.stringify(report, "	"))

	quit(0 if bool(report.get("passed", false)) else 1)