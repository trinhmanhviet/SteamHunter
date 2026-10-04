extends SceneTree

const Catalog = preload("res://scripts/hunt_catalog.gd")
var failures := 0

func _initialize() -> void:
	var ids: Array = Catalog.ids()
	_check(ids == ["moor", "briarwood", "ashbell"], "three large-monster hunts are listed in camp order")
	_check(Catalog.get_hunt("briarwood")["boss_name_key"] == "thornhart_name", "forest uses its own beast name")
	_check(Catalog.get_hunt("ashbell")["boss_name_key"] == "ashbell_name", "third hunt uses the Ashbell identity")
	_check(Catalog.reward("briarwood", true) > Catalog.reward("moor", false), "forest antler break earns extra parts")
	_check(Catalog.reward("ashbell", true) == 8, "Ashbell chamber break adds to its seven-part base reward")
	_check(Catalog.reward("moor", false, 1) == Catalog.reward("moor", false) + 1, "secondary part break adds one reward")
	for id in ids:
		var hunt: Dictionary = Catalog.get_hunt(id)
		for key in ["biome", "boss_script", "small_script", "herb_x", "small_x", "boss_x", "base_reward", "boss_name_key", "hunt_name_key", "region_key", "tip_key"]:
			_check(hunt.has(key), id + " has " + key)
		if hunt.has("boss_script") and hunt.has("small_script"):
			_check(hunt["boss_script"] is Script and hunt["small_script"] is Script, id + " has loaded creature scripts")
		if hunt.has("herb_x") and hunt.has("small_x"):
			_check(hunt["herb_x"].size() == 3 and hunt["small_x"].size() == 4, id + " has a complete encounter route")
	_check(Catalog.get_hunt("missing").is_empty(), "unknown hunt has no record")
	_check(Catalog.reward("missing", true) == 0, "unknown hunt cannot grant a reward")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
