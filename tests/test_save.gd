extends SceneTree

const Store = preload("res://scripts/save_store.gd")
var failures := 0

func _initialize() -> void:
	var original := {"language": "vi", "parts": 7, "forge_level": 2, "hunts_won": 3}
	var encoded: String = Store.encode(original)
	var loaded: Dictionary = Store.decode(encoded)
	_check(loaded["language"] == original["language"] and loaded["parts"] == original["parts"] and loaded["forge_level"] == original["forge_level"] and loaded["hunts_won"] == original["hunts_won"], "progress roundtrip")
	_check(loaded["equipped"] == "blade", "legacy save gains a weapon")
	_check(loaded.get("schema_version") == 4, "legacy save migrates to schema 4")
	_check(loaded.get("chapter") == 1, "legacy save starts at chapter one")
	_check(loaded.get("completed_hunts") == [], "aggregate old wins do not invent specific cleared hunts")
	_check(loaded.get("inventory") == {}, "legacy save receives an empty material inventory")
	_check(loaded.get("hunt_records") == {}, "legacy save receives empty per-hunt records")
	_check(loaded.get("bestiary") == {}, "legacy save receives a discovery book")
	_check(loaded.get("armor_owned") == {"field": true, "ember": false, "thorn": false}, "legacy save receives the starter coat catalog")
	_check(loaded.get("armor_equipped") == "field", "legacy save equips the field coat")
	_check(loaded.get("settings") is Dictionary, "legacy save receives settings")
	var expanded := Store.defaults()
	expanded["chapter"] = 3
	expanded["completed_hunts"] = ["moor", "briarwood", "moor"]
	expanded["inventory"] = {"cinder_vent": 4, "future_material": 2, "bad_count": -8}
	expanded["hunt_records"] = {"moor": {"wins": 2, "best_time_ms": 330000}}
	expanded["bestiary"] = {"cinderback": {"seen": true}}
	expanded["settings"] = {"music_volume": 0.4, "sound_volume": 0.8, "touch_scale": 1.2, "reduced_flash": true}
	var expanded_loaded: Dictionary = Store.decode(Store.encode(expanded))
	_check(expanded_loaded.get("chapter") == 3, "chapter survives roundtrip")
	_check(expanded_loaded.get("completed_hunts") == ["moor", "briarwood"], "cleared hunts remain unique")
	_check(expanded_loaded.get("inventory", {}).get("future_material") == 2, "unknown material IDs survive updates")
	_check(expanded_loaded.get("inventory", {}).get("bad_count") == 0, "negative material counts are clamped")
	_check(expanded_loaded.get("hunt_records", {}).get("moor", {}).get("wins") == 2, "hunt records survive roundtrip")
	_check(expanded_loaded.get("bestiary", {}).has("cinderback"), "discovery survives roundtrip")
	_check(expanded_loaded.get("settings", {}).get("reduced_flash") == true, "settings survive roundtrip")
	var fallback: Dictionary = Store.decode("broken json")
	_check(fallback["parts"] == 0 and fallback["language"] == "en", "invalid save has safe defaults")
	quit(1 if failures > 0 else 0)

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		failures += 1
