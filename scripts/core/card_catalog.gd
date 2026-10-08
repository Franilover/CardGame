class_name CardCatalog
extends RefCounted

static func starter_deck() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	cards.append(_creature("aoris", "Aoris", 1, 4, 5, "Criatura biológica del canon de Garlia."))
	cards.append(_creature("feerin", "Feerin", 1, 3, 6, "Criatura vinculada al sistema de organismos."))
	cards.append(_creature("ligniano", "Ligniano", 2, 5, 7, "Criatura de estructura resistente."))
	cards.append(_object("espada_madera", "Espada de Madera", 1, "Objeto que refuerza una unidad."))
	cards.append(_object("arco_aoris", "Arco Aoris", 1, "Objeto relacionado con Aoris."))
	cards.append(_ium("fluxus", "Fluxus", 1, "IUM asociado al movimiento y la energía cinética."))
	cards.append(_ium("velox", "Velox", 1, "IUM asociado a cinética y transición."))
	cards.append(_ium("fulgor", "Fulgor", 2, "IUM asociado a energía y potencial."))
	cards.append(_process("transicion", "Transición", 1, "Ejecuta un proceso ofensivo básico."))
	cards.append(_process("propagacion", "Propagación", 1, "Proceso que proyecta energía sobre el objetivo."))
	cards.append(_oris("kinetoris", "Kinetoris", 3, "Oris basado en configuraciones de movimiento y resonancia."))
	return cards

static func enemy_deck() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	cards.append(_creature("aoris_enemy", "Aoris Hostil", 1, 3, 5, "Unidad enemiga de prueba."))
	cards.append(_creature("ligniano_enemy", "Ligniano Hostil", 2, 4, 7, "Unidad enemiga resistente."))
	return cards

static func _base(id: String, name: String, type: CardDefinition.CardType, cost: int, description: String) -> CardDefinition:
	var card := CardDefinition.new()
	card.id = id
	card.display_name = name
	card.card_type = type
	card.cost = cost
	card.description = description
	card.canonical_source = id
	return card

static func _creature(id: String, name: String, cost: int, attack: int, health: int, description: String) -> CardDefinition:
	var card := _base(id, name, CardDefinition.CardType.CREATURE, cost, description)
	card.attack = attack
	card.health = health
	card.tags = ["criatura", "organismo"]
	return card

static func _object(id: String, name: String, cost: int, description: String) -> CardDefinition:
	var card := _base(id, name, CardDefinition.CardType.OBJECT, cost, description)
	card.tags = ["objeto"]
	return card

static func _ium(id: String, name: String, cost: int, description: String) -> CardDefinition:
	var card := _base(id, name, CardDefinition.CardType.IUM, cost, description)
	card.tags = ["ium", "magia"]
	return card

static func _oris(id: String, name: String, cost: int, description: String) -> CardDefinition:
	var card := _base(id, name, CardDefinition.CardType.ORIS, cost, description)
	card.tags = ["oris", "magia"]
	return card

static func _process(id: String, name: String, cost: int, description: String) -> CardDefinition:
	var card := _base(id, name, CardDefinition.CardType.PROCESS, cost, description)
	card.tags = ["proceso"]
	return card
