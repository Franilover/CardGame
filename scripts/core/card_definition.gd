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

var movement: int = 1
var attack_range: int = 1
var counter_attack: bool = true

var effect_kind: String = ""
var effect_value: int = 0
var effect_secondary: int = 0
var ability_text: String = ""
var description: String = ""
var canonical_source: String = ""
var image_url: String = ""
var tags: PackedStringArray = []
var source_data: Dictionary = {}

var has_acted: bool = false
var has_attacked: bool = false
var exhausted: bool = false

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
	var copy := CardDefinition.new()
	copy.id = id
	copy.canonical_id = canonical_id
	copy.canonical_table = canonical_table
	copy.display_name = display_name
	copy.card_type = card_type
	copy.cost = cost
	copy.attack = attack
	copy.health = health
	copy.armor = armor
	copy.movement = movement
	copy.attack_range = attack_range
	copy.counter_attack = counter_attack
	copy.effect_kind = effect_kind
	copy.effect_value = effect_value
	copy.effect_secondary = effect_secondary
	copy.ability_text = ability_text
	copy.description = description
	copy.canonical_source = canonical_source
	copy.image_url = image_url
	copy.tags = tags.duplicate()
	copy.source_data = source_data.duplicate(true)
	copy.has_acted = false
	copy.has_attacked = false
	copy.exhausted = false
	return copy

func alive() -> bool:
	return health > 0

func can_attack() -> bool:
	return is_unit() and health > 0 and not has_attacked and not has_acted and not exhausted and attack > 0
