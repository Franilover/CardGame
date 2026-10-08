class_name CardDefinition
extends Resource

enum CardType {
	CREATURE,
	CHARACTER,
	OBJECT,
	IUM,
	ORIS,
	PROCESS
}

var id: String = ""
var canonical_id: String = ""
var canonical_table: String = ""
var display_name: String = ""
var card_type: CardType = CardType.CREATURE
var cost: int = 0
var attack: int = 0
var health: int = 0
var armor: int = 0

var effect_kind: String = ""
var effect_value: int = 0
var effect_secondary: int = 0
var ability_text: String = ""
var description: String = ""
var canonical_source: String = ""
var image_url: String = ""
var tags: PackedStringArray = []
var source_data: Dictionary = {}

var has_attacked := false
var exhausted := false

func is_unit() -> bool:
	return card_type == CardType.CREATURE or card_type == CardType.CHARACTER

func type_name() -> String:
	match card_type:
		CardType.CREATURE:
			return "CRIATURA"
		CardType.CHARACTER:
			return "PERSONAJE"
		CardType.OBJECT:
			return "OBJETO"
		CardType.IUM:
			return "IUM"
		CardType.ORIS:
			return "ORIS"
		CardType.PROCESS:
			return "PROCESO"
	return "CARTA"

func make_runtime_copy() -> CardDefinition:
	return duplicate(true) as CardDefinition

func alive() -> bool:
	return health > 0

func can_attack() -> bool:
	return is_unit() and health > 0 and not has_attacked and not exhausted and attack > 0
