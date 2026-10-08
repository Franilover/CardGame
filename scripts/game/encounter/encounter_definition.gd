class_name EncounterDefinition
extends Resource

## Unión declarativa de tablero + reglas + objetivo + rival + recompensa.
## No ejecuta la batalla.

enum ObjectiveType {
	DEFEAT_ENEMY,
	SURVIVE,
	SPECIAL
}

var encounter_id: String = ""
var display_name: String = ""
var board_id: String = ""
var rule_ids: Array[String] = []
var objective_type: int = ObjectiveType.DEFEAT_ENEMY
var objective_parameters: Dictionary = {}
var enemy_deck_ids: Array[String] = []
var reward_data: Dictionary = {}
var seed: int = 0
var metadata: Dictionary = {}