class_name CardCatalog
extends RefCounted

static func starter_deck() -> Array[CardDefinition]:
	# Las criaturas jugables deben provenir de public.criaturas en Supabase.
	return []

static func enemy_deck() -> Array[CardDefinition]:
	# El mazo enemigo también se construye desde el catálogo canónico.
	return []

static func starter_ium_catalog() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = [
		_ium("fluxus", "Fluxus", 1, "Manifestación de movimiento.", 3),
		_ium("velox", "Velox", 2, "Acelera una manifestación.", 4),
		_ium("fulgor", "Fulgor", 2, "Libera energía concentrada.", 5)
	]
	return cards

static func from_canon(repository: Variant) -> Array[CardDefinition]:
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

static func starter_deck_from_canon(repository: Variant) -> Array[CardDefinition]:
	var all: Array[CardDefinition] = from_canon(repository)
	var battle_cards: Array[CardDefinition] = []

	for card in all:
		if card.card_type == CardDefinition.CardType.CREATURE or card.card_type == CardDefinition.CardType.CHARACTER or card.card_type == CardDefinition.CardType.OBJECT:
			battle_cards.append(card)

	if battle_cards.is_empty():
		return []

	var deck: Array[CardDefinition] = []
	var preferred_types: Array[int] = [
		CardDefinition.CardType.CREATURE,
		CardDefinition.CardType.CREATURE,
		CardDefinition.CardType.CREATURE,
		CardDefinition.CardType.OBJECT,
		CardDefinition.CardType.OBJECT
	]

	for desired_type in preferred_types:
		for card in battle_cards:
			if card.card_type == desired_type:
				deck.append(card.make_runtime_copy())
				break

	while deck.size() < 20:
		deck.append(battle_cards[deck.size() % battle_cards.size()].make_runtime_copy())

	return deck

static func enemy_deck_from_canon(repository: Variant) -> Array[CardDefinition]:
	var all: Array[CardDefinition] = from_canon(repository)
	var creatures: Array[CardDefinition] = []
	var objects: Array[CardDefinition] = []

	for card in all:
		if card.card_type == CardDefinition.CardType.CREATURE:
			creatures.append(card)
		elif card.card_type == CardDefinition.CardType.OBJECT:
			objects.append(card)

	if creatures.is_empty():
		return []

	var deck: Array[CardDefinition] = []

	for i in range(20):
		if not objects.is_empty() and i % 5 == 4:
			deck.append(objects[floori(float(i) / 5.0) % objects.size()].make_runtime_copy())
		else:
			deck.append(creatures[i % creatures.size()].make_runtime_copy())

	return deck

static func _creature_from_canon(row: Dictionary) -> CardDefinition:
	var stats_raw: Variant = row.get("stats_dnd", null)
	var stats: Dictionary = stats_raw if stats_raw is Dictionary else {}

	var ai_raw: Variant = row.get("ia_config", null)
	var ai: Dictionary = ai_raw if ai_raw is Dictionary else {}

	var attack_raw: Variant = ai.get("ataque", null)
	var attack_data: Dictionary = attack_raw if attack_raw is Dictionary else {}

	var attack: int = _value_as_int(attack_data.get("danio", 2), 2)
	if attack <= 0:
		attack = 2

	var health: int = _value_as_int(stats.get("hp_max", 0), 0)
	if health <= 0:
		health = 6

	var cost: int = 1 + floori(clamp(float(health - 5) / 3.0, 0.0, 4.0))

	var nombre_raw: Variant = row.get("nombre", null)
	var display: String = ""
	if nombre_raw != null:
		display = str(nombre_raw).strip_edges()
	if display.is_empty():
		var id_raw: Variant = row.get("id", null)
		if id_raw != null:
			display = str(id_raw).strip_edges()
	if display.is_empty():
		display = "Criatura"

	var desc_raw: Variant = row.get("descripcion", null)
	var desc: String = str(desc_raw).strip_edges() if desc_raw != null else ""

	var id_str: String = str(row.get("id", ""))

	var card: CardDefinition = _creature(id_str, display, cost, attack, health, desc, "canon", id_str)
	card.canonical_table = "criaturas"
	var img_raw: Variant = row.get("imagen_url", null)
	card.image_url = str(img_raw).strip_edges() if img_raw != null else ""
	card.source_data = row.duplicate(true)
	return card

static func _object_from_canon(row: Dictionary, repository: Variant) -> CardDefinition:
	var item_id: String = str(row.get("id", ""))
	var game_data: Dictionary = {}

	for game_row in repository.get_table("items_game"):
		if game_row is Dictionary and str(game_row.get("item_id", "")) == item_id:
			game_data = game_row
			break

	if game_data.is_empty():
		return null

	var props: Dictionary = game_data.get("propiedades", {}) if game_data.get("propiedades") is Dictionary else {}
	var effect_value: int = _value_as_int(props.get("danio", 2), 2)
	if effect_value <= 0:
		effect_value = 2

	var card: CardDefinition = _object(
		item_id,
		str(row.get("nombre", "Objeto")),
		1 + floori(clamp(float(effect_value) / 4.0, 0.0, 2.0)),
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


static func _value_as_int(value: Variant, fallback: int = 0) -> int:
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return floori(value)
		TYPE_STRING:
			var text_value: String = str(value).strip_edges()
			return text_value.to_int() if not text_value.is_empty() else fallback
	return fallback

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
	var lower_name: String = name.to_lower()
	card.movement = 2 if lower_name.contains("aoris") else 1
	card.attack_range = 2 if lower_name.contains("aoris") else 1
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
