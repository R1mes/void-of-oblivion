class_name ActionValueSystem
extends RefCounted

static func get_next_actor(units: Array) -> Dictionary:
	var living: Array[CombatUnit] = []
	for u in units:
		if u is CombatUnit and u.is_alive():
			living.append(u)
	if living.is_empty():
		return {"unit": null, "tick": 0.0}

	var min_av := INF
	for unit in living:
		min_av = minf(min_av, unit.action_value)

	for unit in living:
		unit.action_value -= min_av

	var next_unit: CombatUnit = null
	var lowest := INF
	for unit in living:
		if unit.action_value < lowest:
			lowest = unit.action_value
			next_unit = unit
	return {"unit": next_unit, "tick": min_av}

static func preview_turn_order(units: Array, count: int = 8) -> Array:
	var clones: Array[Dictionary] = []
	for u in units:
		if u is CombatUnit and u.is_alive():
			clones.append({"unit": u, "av": u.action_value})

	var order: Array[CombatUnit] = []
	while order.size() < count and not clones.is_empty():
		var min_av := INF
		for entry in clones:
			min_av = minf(min_av, entry.av)

		for entry in clones:
			entry.av -= min_av

		var best_idx := -1
		min_av = INF
		for i in range(clones.size()):
			if clones[i].av < min_av:
				min_av = clones[i].av
				best_idx = i

		if best_idx < 0:
			break

		var picked: CombatUnit = clones[best_idx].unit
		order.append(picked)
		clones[best_idx].av = clones[best_idx].unit.base_action_value

	return order
