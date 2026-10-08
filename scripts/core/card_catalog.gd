class_name CardCatalog
extends RefCounted

static func starter_deck() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []

	var base: Array[CardDefinition] = [
		_creature("aoris", "Aoris", 1, 4, 5, "Criatura veloz.", "criatura", "aoris"),
		_creature("feerin", "Feerin", 1, 3, 6, "Criatura resistente.", "criatura", "feerin"),
		_creature("ligniano", "Ligniano", 2, 5, 7, "Criatura robusta.", "criatura", "ligniano"),
		_creature("guardian", "Guardián Verde", 3, 6, 8, "Defensor de primera línea.", "criatura", "guardian"),
		_object("espada_madera", "Espada de Madera", 1, "Fortalece una criatura.", 2, 1),
		_object("arco_aoris", "Arco Aoris", 2, "Fortalece y aumenta alcance.", 2, 1),
		_ium("fluxus", "Fluxus", 1, "Manifestación de movimiento.", 3),
		_ium("velox", "Velox", 2, "Acelera una manifestación.", 4),
		_ium("fulgor", "Fulgor", 2, "Libera energía concentrada.", 5),
		_process("transicion", "Transición", 1, "Transformación de estado.", 3),
		_process("propagacion", "Propagación", 2, "Extiende la manifestación.", 4),
		_oris("kinetoris", "Kinetoris", 4, "Movimiento y sonido.", 8)
	]

	for i in range(20):
		cards.append(base[i % base.size()].make_runtime_copy())

	return cards

static func enemy_deck() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	var base: Array[CardDefinition] = [
		_creature("enemy_aoris", "Aoris Hostil", 1, 3, 5, "Unidad enemiga.", "criatura", "enemy_aoris"),
		_creature("enemy_ligniano", "Ligniano Hostil", 2, 5, 7, "Unidad enemiga resistente.", "criatura", "enemy_ligniano"),
		_creature("enemy_guardian", "Guardián Hostil", 3, 6, 9, "Unidad pesada.", "criatura", "enemy_guardian"),
		_process("enemy_flux", "Pulso", 2, "Daño directo.", 3),
		_ium("enemy_fulgor", "Descarga", 3, "Daño energético.", 6)
	]

	for i in range(20):
		cards.append(base[i % base.size()].make_runtime_copy())

	return cards

static func from_canon(repository: GarliaCanonRepository) -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []

	for row in repository.get_table("criaturas"):
		if row is Dictionary:
			cards.append(_creature_from_canon(row))

	for row in repository.get_table("items"):
		if row is Dictionary:
			var card: CardDefinition = _object_from_canon(row, repository)
			if card != null:
				cards.append(card)

	for row in repository.get_table("iums"):
		if row is Dictionary:
			cards.append(_ium_from_canon(row))

	for row in repository.get_table("procesos"):
		if row is Dictionary:
			cards.append(_process_from_canon(row))

	for row in repository.get_table("oris"):
		if row is Dictionary:
			cards.append(_oris_from_canon(row))

	return cards

static func starter_deck_from_canon(repository: GarliaCanonRepository) -> Array[CardDefinition]:
	var all: Array[CardDefinition] = from_canon(repository)
	if all.is_empty():
		return starter_deck()

	var deck: Array[CardDefinition] = []
	var preferred_types: Array[int] = [
		CardDefinition.CardType.CREATURE,
		CardDefinition.CardType.CREATURE,
		CardDefinition.CardType.CREATURE,
		CardDefinition.CardType.OBJECT,
		CardDefinition.CardType.IUM,
		CardDefinition.CardType.PROCESS,
		CardDefinition.CardType.ORIS
	]

	for desired_type in preferred_types:
		for card in all:
			if card.card_type == desired_type:
				deck.append(card.make_runtime_copy())
				break

	while deck.size() < 20:
		deck.append(all[deck.size() % all.size()].make_runtime_copy())

	return deck

static func enemy_deck_from_canon(repository: GarliaCanonRepository) -> Array[CardDefinition]:
	var all := from_canon(repository)
	var deck: Array[CardDefinition] = []
	var creatures: Array[CardDefinition] = []
	var effects: Array[CardDefinition] = []

	for card in all:
		if card.card_type == CardDefinition.CardType.CREATURE:
			creatures.append(card)
		elif card.card_type == CardDefinition.CardType.IUM or card.card_type == CardDefinition.CardType.PROCESS or card.card_type == CardDefinition.CardType.ORIS:
			effects.append(card)

	if creatures.is_empty():
		return enemy_deck()

	for i in range(20):
		if not effects.is_empty() and i % 5 == 4:
			deck.append(effects[(int(i / 5)) % effects.size()].make_runtime_copy())
		else:
			deck.append(creatures[i % creatures.size()].make_runtime_copy())

	return deck

static func _creature_from_canon(row: Dictionary) -> CardDefinition:
	var stats: Dictionary = row.get("stats_dnd", {}) if row.get("stats_dnd") is Dictionary else {}
	var ai: Dictionary = row.get("ia_config", {}) if row.get("ia_config") is Dictionary else {}
	var attack_data: Dictionary = ai.get("ataque", {}) if ai.get("ataque") is Dictionary else {}

	var attack: int = int(attack_data.get("danio", 2))
	var health: int = int(stats.get("hp_max", 6))
	if health <= 0:
		var bio: Dictionary = row.get("biologia_calculada", {}) if row.get("biologia_calculada") is Dictionary else {}
		var stability: float = float(bio.get("estabilidad", 0.5))
		health = 5 + int(clamp(stability * 5.0, 0.0, 5.0))

	var cost: int = 1 + int(clamp(float(health - 5) / 3.0, 0.0, 4.0))
	var card: CardDefinition = _creature(
		str(row.get("id", "")),
		str(row.get("nombre", "Criatura")),
		cost,
		attack,
		health,
		str(row.get("descripcion", "")),
		"canon",
		str(row.get("id", ""))
	)
	card.canonical_table = "criaturas"
	card.image_url = str(row.get("imagen_url", ""))
	card.source_data = row.duplicate(true)
	return card

static func _object_from_canon(row: Dictionary, repository: GarliaCanonRepository) -> CardDefinition:
	var item_id: String = str(row.get("id", ""))
	var game_data: Dictionary = {}

	for game_row in repository.get_table("items_game"):
		if game_row is Dictionary and str(game_row.get("item_id", "")) == item_id:
			game_data = game_row
			break

	if game_data.is_empty():
		return null

	var props: Dictionary = game_data.get("propiedades", {}) if game_data.get("propiedades") is Dictionary else {}
	var effect_value: int = int(props.get("danio", 2))
	if effect_value <= 0:
		effect_value = 2

	var card: CardDefinition = _object(
		item_id,
		str(row.get("nombre", "Objeto")),
		1 + int(clamp(effect_value / 4.0, 0.0, 2.0)),
		str(row.get("descripcion", "Objeto canónico.")),
		effect_value,
		1
	)
	card.canonical_table = "items"
	card.image_url = str(row.get("imagen_url", ""))
	card.source_data = row.duplicate(true)
	card.source_data["items_game"] = game_data
	return card

static func _ium_from_canon(row: Dictionary) -> CardDefinition:
	var name: String = str(row.get("nombre", "IUM"))
	var lower: String = name.to_lower()
	var value: int = 3
	var cost: int = 1

	if lower.contains("velox"):
		value = 4
		cost = 2
	elif lower.contains("fulgor"):
		value = 5
		cost = 2
	elif lower.contains("ruina"):
		value = 6
		cost = 3

	var card: CardDefinition = _ium(
		str(row.get("id", "")),
		name,
		cost,
		str(row.get("extra", row.get("detalle", "IUM canónico."))),
		value
	)
	card.canonical_table = "iums"
	card.source_data = row.duplicate(true)
	return card

static func _process_from_canon(row: Dictionary) -> CardDefinition:
	var card: CardDefinition = _process(
		str(row.get("id", "")),
		str(row.get("nombre", "Proceso")),
		2,
		str(row.get("descripcion", row.get("transformacion", "Proceso canónico."))),
		4
	)
	card.canonical_table = "procesos"
	card.source_data = row.duplicate(true)
	return card

static func _oris_from_canon(row: Dictionary) -> CardDefinition:
	var name := str(row.get("nombre", "Oris"))
	var value := 8
	if name.to_lower().contains("gravioris"):
		value = 7
	var card: CardDefinition = _oris(
		str(row.get("id", "")),
		name,
		4,
		str(row.get("descripcion", row.get("dominio", "Oris canónico."))),
		value
	)
	card.canonical_table = "oris"
	card.source_data = row.duplicate(true)
	return card

static func _base(id: String, name: String, type: CardDefinition.CardType, cost: int, description: String) -> CardDefinition:
	var card := CardDefinition.new()
	card.id = id
	card.canonical_id = id
	card.display_name = name
	card.card_type = type
	card.cost = cost
	card.description = description
	card.canonical_source = id
	return card

static func _creature(id: String, name: String, cost: int, attack: int, health: int, description: String, source: String = "local", canonical_id: String = "") -> CardDefinition:
	var card := _base(id, name, CardDefinition.CardType.CREATURE, cost, description)
	card.attack = attack
	card.health = health
	card.tags = ["criatura", "organismo"]
	card.canonical_source = source
	if not canonical_id.is_empty():
		card.canonical_id = canonical_id
	return card

static func _object(id: String, name: String, cost: int, description: String, value: int = 2, secondary: int = 0) -> CardDefinition:
	var card := _base(id, name, CardDefinition.CardType.OBJECT, cost, description)
	card.effect_kind = "buff"
	card.effect_value = value
	card.effect_secondary = secondary
	card.tags = ["objeto"]
	return card

static func _ium(id: String, name: String, cost: int, description: String, value: int = 3) -> CardDefinition:
	var card := _base(id, name, CardDefinition.CardType.IUM, cost, description)
	card.effect_kind = "damage"
	card.effect_value = value
	card.tags = ["ium", "magia"]
	return card

static func _oris(id: String, name: String, cost: int, description: String, value: int = 8) -> CardDefinition:
	var card := _base(id, name, CardDefinition.CardType.ORIS, cost, description)
	card.effect_kind = "damage"
	card.effect_value = value
	card.tags = ["oris", "magia"]
	return card

static func _process(id: String, name: String, cost: int, description: String, value: int = 4) -> CardDefinition:
	var card := _base(id, name, CardDefinition.CardType.PROCESS, cost, description)
	card.effect_kind = "damage"
	card.effect_value = value
	card.tags = ["proceso"]
	return card
