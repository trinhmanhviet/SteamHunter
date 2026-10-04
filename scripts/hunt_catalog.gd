extends RefCounted

const Cinderback = preload("res://scripts/cinderback.gd")
const MireRat = preload("res://scripts/mire_rat.gd")
const Thornhart = preload("res://scripts/thornhart.gd")
const Bristlehog = preload("res://scripts/bristlehog.gd")
const AshbellRam = preload("res://scripts/ashbell_ram.gd")

const HUNTS := {
	"moor": {
		"biome": "moor",
		"boss_script": Cinderback,
		"small_script": MireRat,
		"herb_x": [385.0, 1375.0, 2380.0],
		"small_x": [605.0, 1060.0, 1640.0, 2190.0],
		"boss_x": 2700.0,
		"boss_name_key": "boss_name",
		"hunt_name_key": "hunt_name",
		"region_key": "moor_region",
		"tip_key": "hunt_tip",
		"trophy_id": "ash_plate",
		"elements": {"heat": 0.35, "shock": 1.35},
		"statuses": {"snare": 0.80},
		"snare_threshold": 52.0,
		"base_reward": 3
	},
	"briarwood": {
		"biome": "briarwood",
		"boss_script": Thornhart,
		"small_script": Bristlehog,
		"herb_x": [415.0, 1350.0, 2330.0],
		"small_x": [570.0, 1120.0, 1700.0, 2240.0],
		"boss_x": 2700.0,
		"boss_name_key": "thornhart_name",
		"hunt_name_key": "thornhart_name",
		"region_key": "briarwood_region",
		"tip_key": "briarwood_tip",
		"trophy_id": "thorn_antler",
		"elements": {"heat": 1.45, "shock": 0.75},
		"statuses": {"snare": 0.45},
		"snare_threshold": 65.0,
		"base_reward": 5
	},
	"ashbell": {
		"biome": "moor",
		"boss_script": AshbellRam,
		"small_script": MireRat,
		"herb_x": [430.0, 1420.0, 2350.0],
		"small_x": [650.0, 1180.0, 1760.0, 2250.0],
		"boss_x": 2700.0,
		"boss_name_key": "ashbell_name",
		"hunt_name_key": "ashbell_name",
		"region_key": "moor_region",
		"tip_key": "ashbell_tip",
		"trophy_id": "bell_core",
		"elements": {"heat": 1.0, "shock": 0.30},
		"statuses": {"snare": 1.35},
		"snare_threshold": 45.0,
		"base_reward": 7
	}
}

static func ids() -> Array[String]:
	return ["moor", "briarwood", "ashbell"]

static func get_hunt(id: String) -> Dictionary:
	return HUNTS.get(id, {})

static func reward(id: String, armor_broken: bool, extra_breaks: int = 0) -> int:
	var hunt := get_hunt(id)
	if hunt.is_empty():
		return 0
	return int(hunt["base_reward"]) + (1 if armor_broken else 0) + maxi(0, extra_breaks)

static func trophy_reward(id: String, armor_broken: bool) -> Dictionary:
	var hunt := get_hunt(id)
	if hunt.is_empty() or not hunt.has("trophy_id"):
		return {}
	return {"id": str(hunt["trophy_id"]), "count": 2 if armor_broken else 1}

static func element_multiplier(id: String, element_id: String) -> float:
	var hunt := get_hunt(id)
	var elements: Dictionary = hunt.get("elements", {}) if hunt.get("elements", {}) is Dictionary else {}
	return maxf(0.0, float(elements.get(element_id, 1.0)))

static func status_multiplier(id: String, status_id: String) -> float:
	var hunt := get_hunt(id)
	var statuses: Dictionary = hunt.get("statuses", {}) if hunt.get("statuses", {}) is Dictionary else {}
	return maxf(0.0, float(statuses.get(status_id, 1.0)))

static func status_threshold(id: String, status_id: String) -> float:
	var hunt := get_hunt(id)
	if status_id == "snare":
		return maxf(1.0, float(hunt.get("snare_threshold", 50.0)))
	return 50.0
