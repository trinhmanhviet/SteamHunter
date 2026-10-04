extends SceneTree

const Catalog = preload("res://scripts/hunt_catalog.gd")
const Rules = preload("res://scripts/rules.gd")
const Store = preload("res://scripts/save_store.gd")

var failures := 0

func _initialize() -> void:
	var trophies := {
		"moor": "ash_plate",
		"briarwood": "thorn_antler",
		"ashbell": "bell_core"
	}
	for hunt_id in trophies:
		var normal: Dictionary = Catalog.trophy_reward(hunt_id, false)
		var broken: Dictionary = Catalog.trophy_reward(hunt_id, true)
		_check(normal == {"id": trophies[hunt_id], "count": 1}, hunt_id + " grants its own trophy")
		_check(broken == {"id": trophies[hunt_id], "count": 2}, hunt_id + " part break grants a bonus trophy")

	_check(Rules.coat_ids() == ["field", "ember", "thorn"], "three coat choices are cataloged")
	_check(Rules.coat_recipe("ember") == {"parts": 4, "material": "ash_plate", "count": 2}, "ember coat uses Cinderback trophies")
	_check(Rules.coat_recipe("thorn") == {"parts": 4, "material": "thorn_antler", "count": 2}, "thorn vest uses Thornhart trophies")
	var progress := Store.defaults()
	progress["parts"] = 4
	progress["inventory"] = {"ash_plate": 2, "thorn_antler": 1}
	_check(Rules.can_craft_coat(progress, "ember"), "complete recipe can be crafted")
	_check(not Rules.can_craft_coat(progress, "thorn"), "missing trophy blocks a recipe")
	_check(Rules.coat_max_health("ember") > Rules.coat_max_health("field"), "ember coat increases health")
	_check(Rules.coat_damage(40, "ember") < Rules.coat_damage(40, "field"), "ember coat softens incoming damage")
	_check(Rules.coat_max_stamina("thorn") > Rules.coat_max_stamina("field"), "thorn vest increases stamina")
	_check(Rules.coat_dodge_cost("thorn") < Rules.coat_dodge_cost("field"), "thorn vest makes dodging cheaper")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
