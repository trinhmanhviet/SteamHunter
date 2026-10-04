extends SceneTree

const Catalog = preload("res://scripts/hunt_catalog.gd")
const Rules = preload("res://scripts/rules.gd")
const Store = preload("res://scripts/save_store.gd")

var failures := 0

func _initialize() -> void:
	_check(Rules.tuning_ids() == ["plain", "tempered", "ember", "briar", "resonant"], "five tuning choices are stable")
	_check(Rules.tuning_recipe("ember") == {"parts": 3, "material": "ash_plate", "count": 2}, "ember branch consumes ash plates")
	_check(Rules.tuning_recipe("briar")["material"] == "thorn_antler", "briar branch consumes thorn antlers")
	_check(Rules.tuning_recipe("resonant")["material"] == "bell_core", "resonant branch consumes bell cores")

	var progress := Store.defaults()
	progress["parts"] = 3
	progress["inventory"] = {"ash_plate": 2}
	_check(Rules.can_craft_tuning(progress, "blade", "ember"), "complete tuning recipe can be crafted")
	_check(not Rules.can_craft_tuning(progress, "blade", "resonant"), "missing trophy blocks a tuning recipe")

	_check(Catalog.element_multiplier("briarwood", "heat") > 1.0, "Thornhart is weak to heat")
	_check(Catalog.element_multiplier("moor", "heat") < 1.0, "Cinderback resists heat")
	_check(Catalog.element_multiplier("moor", "shock") > 1.0, "Cinderback is weak to shock")
	_check(Catalog.element_multiplier("ashbell", "shock") < 1.0, "Ashbell resists shock")
	_check(Catalog.status_multiplier("ashbell", "snare") > Catalog.status_multiplier("briarwood", "snare"), "Ashbell is more vulnerable to snare than Thornhart")

	var base := 20
	var hot_weak := Rules.tuned_damage(base, "blade", "ember", Catalog.element_multiplier("briarwood", "heat"))
	var hot_resist := Rules.tuned_damage(base, "blade", "ember", Catalog.element_multiplier("moor", "heat"))
	_check(hot_weak > hot_resist and hot_resist > base, "heat bonus respects monster matchup")
	_check(Rules.tuned_damage(base, "blade", "tempered", 1.0) == base + 5, "tempered branch adds reliable raw damage")
	var blade_snare := Rules.tuning_status_gain("blade", "briar", Catalog.status_multiplier("ashbell", "snare"))
	var twins_snare := Rules.tuning_status_gain("twins", "briar", Catalog.status_multiplier("ashbell", "snare"))
	_check(twins_snare > blade_snare and blade_snare > 0.0, "weapon status scale changes snare buildup")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
