extends RefCounted

const WEAPON_STATS := {
	"blade": {"cost": 0, "quick_damage": 12, "heavy_damage": 20, "charge_bonus": 18, "quick_reach": 110.0, "heavy_reach": 150.0, "quick_cost": 12.0, "heavy_cost": 28.0, "quick_time": 0.20, "heavy_time": 0.32},
	"pike": {"cost": 5, "quick_damage": 9, "heavy_damage": 17, "charge_bonus": 15, "quick_reach": 170.0, "heavy_reach": 225.0, "quick_cost": 11.0, "heavy_cost": 25.0, "quick_time": 0.18, "heavy_time": 0.31},
	"maul": {"cost": 7, "quick_damage": 16, "heavy_damage": 29, "charge_bonus": 24, "quick_reach": 94.0, "heavy_reach": 128.0, "quick_cost": 17.0, "heavy_cost": 36.0, "quick_time": 0.27, "heavy_time": 0.46}
}

static func weapon_ids() -> Array[String]:
	return ["blade", "pike", "maul"]

static func weapon_cost(weapon: String) -> int:
	return int(WEAPON_STATS.get(weapon, WEAPON_STATS["blade"])["cost"])

static func can_spend_stamina(current: float, cost: float) -> bool:
	return current >= cost and cost >= 0.0

static func attack_damage(kind: String, charge: float, forge_level: int, weapon: String = "blade") -> int:
	var stats: Dictionary = WEAPON_STATS.get(weapon, WEAPON_STATS["blade"])
	var base: int = int(stats["quick_damage"]) if kind == "quick" else int(stats["heavy_damage"])
	var bonus: int = int(round(clampf(charge, 0.0, 1.0) * int(stats["charge_bonus"]))) if kind == "heavy" else 0
	return base + bonus + maxi(0, forge_level) * 5

static func attack_reach(kind: String, weapon: String = "blade") -> float:
	var stats: Dictionary = WEAPON_STATS.get(weapon, WEAPON_STATS["blade"])
	return float(stats["quick_reach"]) if kind == "quick" else float(stats["heavy_reach"])

static func attack_cost(kind: String, weapon: String = "blade") -> float:
	var stats: Dictionary = WEAPON_STATS.get(weapon, WEAPON_STATS["blade"])
	return float(stats["quick_cost"]) if kind == "quick" else float(stats["heavy_cost"])

static func attack_duration(kind: String, weapon: String = "blade") -> float:
	var stats: Dictionary = WEAPON_STATS.get(weapon, WEAPON_STATS["blade"])
	return float(stats["quick_time"]) if kind == "quick" else float(stats["heavy_time"])

static func forge_cost(forge_level: int) -> int:
	return 3 + maxi(0, forge_level) * 2

static func hunt_reward(armor_broken: bool) -> int:
	return 4 if armor_broken else 3
