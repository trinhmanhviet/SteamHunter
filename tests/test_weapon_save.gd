extends SceneTree

const Store = preload("res://scripts/save_store.gd")

func _initialize() -> void:
	var old_save := Store.decode('{"language":"vi","parts":9,"forge_level":2,"hunts_won":4}')
	_check(old_save["schema_version"] == 4, "old save migrates to schema four")
	_check(old_save["weapons"] == {"blade": true, "counter": false, "twins": false, "pike": false, "maul": false}, "old save receives the expanded weapon roster")
	_check(old_save["equipped"] == "blade", "old save keeps a valid equipped weapon")
	var forged := old_save.duplicate(true)
	forged["weapons"]["counter"] = true
	forged["equipped"] = "counter"
	_check(Store.decode(Store.encode(forged)) == forged, "new gear survives save roundtrip")
	var invalid := Store.decode('{"weapons":{"blade":false,"counter":false,"twins":false,"pike":false,"maul":false},"equipped":"maul"}')
	_check(invalid["weapons"]["blade"] and invalid["equipped"] == "blade", "invalid locked loadout falls back safely")
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
