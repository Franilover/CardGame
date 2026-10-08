class_name BoardCellDefinition
extends Resource

## Datos estáticos de una casilla.
## No ejecuta gameplay.

var index: int = -1
var terrain_id: String = "normal"
var tags: PackedStringArray = []
var rule_ids: Array[String] = []
var blocked: bool = false
var metadata: Dictionary = {}