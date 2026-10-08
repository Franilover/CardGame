class_name CardDefinition
extends Resource

enum CardType {
	CREATURE,
	OBJECT,
	IUM,
	ORIS,
	PROCESS
}

@export var id: String = ""
@export var display_name: String = ""
@export var card_type: CardType = CardType.CREATURE
@export var cost: int = 0
@export var attack: int = 0
@export var health: int = 0
@export var description: String = ""
@export var canonical_source: String = ""
@export var tags: PackedStringArray = []

func is_unit() -> bool:
	return card_type == CardType.CREATURE

func type_name() -> String:
	return CardType.keys()[card_type]
