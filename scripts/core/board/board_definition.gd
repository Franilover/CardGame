class_name BoardDefinition
extends Resource

## Definición estática de un tablero.
## Las reglas se interpretarán fuera de aquí.

var board_id: String = ""
var display_name: String = ""
var rows: int = 3
var columns: int = 3
var cells: Array[BoardCellDefinition] = []
var global_rule_ids: Array[String] = []
var metadata: Dictionary = {}

func cell_count() -> int:
	return rows * columns

func get_cell(index: int) -> BoardCellDefinition:
	if index < 0 or index >= cells.size():
		return null
	return cells[index]