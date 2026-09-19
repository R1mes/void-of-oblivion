class_name MemospriteChargeComponent
extends RefCounted

signal charge_changed(current: float, max_val: float)
signal charge_full()
signal charge_consumed(amount: float)

var charge: float = 0.0
var max_charge: float = 100.0
var enabled: bool = true

func _init(p_max_charge: float = 100.0, p_enabled: bool = true) -> void:
	max_charge = p_max_charge
	enabled = p_enabled
	charge = 0.0

func add_charge(amount: float) -> void:
	if not enabled or amount <= 0.0:
		return
	var old_charge := charge
	charge = minf(charge + amount, max_charge)
	if charge != old_charge:
		charge_changed.emit(charge, max_charge)
		if charge >= max_charge and old_charge < max_charge:
			charge_full.emit()

func remove_charge(amount: float) -> bool:
	if not enabled or amount <= 0.0:
		return false
	if charge < amount:
		return false
	charge = maxf(charge - amount, 0.0)
	charge_changed.emit(charge, max_charge)
	return true

func consume_charge(amount: float) -> bool:
	var success := remove_charge(amount)
	if success:
		charge_consumed.emit(amount)
	return success

func set_charge(amount: float) -> void:
	if not enabled:
		return
	var old_charge := charge
	charge = clampf(amount, 0.0, max_charge)
	if charge != old_charge:
		charge_changed.emit(charge, max_charge)
		if charge >= max_charge and old_charge < max_charge:
			charge_full.emit()

func get_charge() -> float:
	return charge

func is_fully_charged() -> bool:
	return enabled and charge >= max_charge
