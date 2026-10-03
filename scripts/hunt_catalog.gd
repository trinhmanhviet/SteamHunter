extends RefCounted

const Cinderback = preload("res://scripts/cinderback.gd")
const MireRat = preload("res://scripts/mire_rat.gd")
const Thornhart = preload("res://scripts/thornhart.gd")
const Bristlehog = preload("res://scripts/bristlehog.gd")

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
		"base_reward": 5
	}
}

static func ids() -> Array[String]:
	return ["moor", "briarwood"]

static func get_hunt(id: String) -> Dictionary:
	return HUNTS.get(id, {})

static func reward(id: String, armor_broken: bool, extra_breaks: int = 0) -> int:
	var hunt := get_hunt(id)
	if hunt.is_empty():
		return 0
	return int(hunt["base_reward"]) + (1 if armor_broken else 0) + maxi(0, extra_breaks)
