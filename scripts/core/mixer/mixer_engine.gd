class_name MixerEngine
extends RefCounted

static func find_process(mixer: MixerState, process_catalog: Array[CardDefinition]) -> CardDefinition:
	if mixer == null:
		return null
	var inputs: Array[CardDefinition] = mixer.get_iums()
	if inputs.size() < 2:
		return null

	var input_ids: Array[String] = []
	for card in inputs:
		input_ids.append(card.canonical_id if not card.canonical_id.is_empty() else card.id)
	input_ids.sort()

	for process in process_catalog:
		if process == null:
			continue
		var raw_recipe: Variant = process.source_data.get("ium_ids", null)
		if not raw_recipe is Array:
			continue

		var recipe_ids: Array[String] = []
		for raw_id in raw_recipe:
			recipe_ids.append(str(raw_id))
		recipe_ids.sort()

		if recipe_ids == input_ids:
			return process
	return null

static func describe(mixer: MixerState) -> String:
	if mixer == null:
		return "Mezclador vacío."
	var names: Array[String] = []
	for card in mixer.get_iums():
		names.append(card.display_name)
	if names.is_empty():
		return "Mezclador vacío."
	return " + ".join(names)
