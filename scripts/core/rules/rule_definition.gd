class_name RuleDefinition
extends Resource

## Definición declarativa de una regla.
## No contiene código de resolución.

enum Category {
	GLOBAL,
	CELL,
	TURN,
	INTERACTION
}

var rule_id: String = ""
var display_name: String = ""
var category: int = Category.GLOBAL
var trigger: String = ""
var operation: String = ""
var parameters: Dictionary = {}
var tags: PackedStringArray = []
var metadata: Dictionary = {}