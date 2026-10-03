extends RefCounted

const Catalog = preload("res://scripts/weapon_catalog.gd")

static func weapon_ids() -> Array[String]:
	return Catalog.weapon_ids()

static func required_weapon_ids() -> Array[String]:
	return Catalog.required_ids()

static func weapon_cost(weapon: String) -> int:
	return int(Catalog.weapon(weapon)["cost"])

static func can_spend_stamina(current: float, cost: float) -> bool:
	return current >= cost and cost >= 0.0

static func attack_damage(kind: String, charge: float, forge_level: int, weapon: String = "blade") -> int:
	return action_damage(_resolve_action(kind, weapon), charge, forge_level, weapon)

static func attack_reach(kind: String, weapon: String = "blade") -> float:
	return float(action(_resolve_action(kind, weapon), weapon).get("reach", 0.0))

static func attack_cost(kind: String, weapon: String = "blade") -> float:
	return float(action(_resolve_action(kind, weapon), weapon).get("stamina", 0.0))

static func attack_duration(kind: String, weapon: String = "blade") -> float:
	return float(action(_resolve_action(kind, weapon), weapon).get("duration", 0.0))

static func weapon(weapon_id: String) -> Dictionary:
	return Catalog.weapon(weapon_id)

static func action_ids(weapon_id: String) -> Array[String]:
	return Catalog.action_ids(weapon_id)

static func action(action_id: String, weapon_id: String = "blade") -> Dictionary:
	return Catalog.action(weapon_id, _resolve_action(action_id, weapon_id))

static func entry_action(weapon_id: String) -> String:
	return str(weapon(weapon_id)["entry"])

static func followup_action(current: String, token: String, weapon_id: String) -> String:
	var branches: Dictionary = weapon(weapon_id)["followups"].get(current, {})
	return str(branches.get(token, ""))

static func action_damage(action_id: String, charge: float, forge_level: int, weapon_id: String = "blade") -> int:
	var data := action(action_id, weapon_id)
	var bonus := roundi(clampf(charge, 0.0, 1.0) * int(data.get("charge_bonus", 0)))
	return int(data.get("damage", 0)) + bonus + maxi(0, forge_level) * 5

static func action_impact(action_id: String, weapon_id: String = "blade") -> String:
	if action_id == "quick":
		return "light"
	if action_id == "heavy":
		return "heavy"
	return str(action(action_id, weapon_id).get("impact", "light"))

static func _resolve_action(action_id: String, weapon_id: String) -> String:
	var record := weapon(weapon_id)
	if action_id == "quick":
		return str(record["entry"])
	if action_id == "heavy":
		return str(record["heavy"])
	return action_id

static func forge_cost(forge_level: int) -> int:
	return 3 + maxi(0, forge_level) * 2

static func hunt_reward(armor_broken: bool) -> int:
	return 4 if armor_broken else 3
