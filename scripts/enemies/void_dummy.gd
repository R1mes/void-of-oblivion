class_name VoidDummy
extends RefCounted

const ID := "void_dummy"

static func create_unit() -> CombatUnit:
	var unit := CombatUnit.new()
	unit.setup_from_template({
		"id": ID,
		"name": "Манекен-Мишень",
		"element": CombatConstants.Element.PHYSICAL,
		"path": CombatConstants.Path.PRESERVATION,
		"is_ally": false,
		"is_elite": false,
		"stats": {
			"hp": 101250,
			"atk": 150,
			"def": 300,
			"spd": 80,
			"effect_res": 0.00,
		},
		"toughness": 500,
		# Манекен уязвим ко всем элементам в игре
		"weaknesses": [
			CombatConstants.Element.PHYSICAL,
			CombatConstants.Element.ICE,
			CombatConstants.Element.FIRE,
			CombatConstants.Element.WIND,
			CombatConstants.Element.LIGHTNING,
			CombatConstants.Element.QUANTUM,
			CombatConstants.Element.IMAGINARY
		],
	})
	return unit
