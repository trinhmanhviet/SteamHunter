extends RefCounted

const SAVE_PATH := "user://mist_and_iron_save.json"
const SCHEMA_VERSION := 4
const Rules = preload("res://scripts/rules.gd")

static func defaults() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"language": "en",
		"parts": 0,
		"forge_level": 0,
		"hunts_won": 0,
		"weapons": {"blade": true, "counter": false, "twins": false, "pike": false, "maul": false},
		"equipped": "blade",
		"chapter": 1,
		"completed_hunts": [],
		"hunt_records": {},
		"inventory": {},
		"bestiary": {},
		"armor_owned": {"field": true, "ember": false, "thorn": false},
		"armor_equipped": "field",
		"companion_unlocked": false,
		"settings": {"music_volume": 1.0, "sound_volume": 1.0, "touch_scale": 1.0, "reduced_flash": false}
	}

static func encode(progress: Dictionary) -> String:
	return JSON.stringify(_clean(progress))

static func decode(source: String) -> Dictionary:
	var value := _parse_dictionary(source)
	if value.is_empty():
		return defaults()
	return _clean(value)

static func load_progress(path: String = SAVE_PATH) -> Dictionary:
	for candidate in [path, path + ".bak"]:
		var value := _parse_dictionary(_read_text(candidate))
		if not value.is_empty():
			return _clean(value)
	return defaults()

static func save_progress(progress: Dictionary, path: String = SAVE_PATH) -> bool:
	var payload := encode(progress)
	var temporary := path + ".tmp"
	if not _write_text(temporary, payload):
		return false
	var old_source := _read_text(path)
	if not _parse_dictionary(old_source).is_empty():
		var backup_temporary := path + ".bak.tmp"
		if not _write_text(backup_temporary, old_source):
			return false
		if not _replace_file(backup_temporary, path + ".bak"):
			return false
	return _replace_file(temporary, path)

static func _parse_dictionary(source: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(source) != OK or not parser.data is Dictionary:
		return {}
	return parser.data

static func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

static func _write_text(path: String, value: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(value)
	file.flush()
	file.close()
	return _read_text(path) == value

static func _replace_file(source: String, destination: String) -> bool:
	var from := ProjectSettings.globalize_path(source)
	var to := ProjectSettings.globalize_path(destination)
	if DirAccess.rename_absolute(from, to) == OK:
		return true
	if not FileAccess.file_exists(destination):
		return false
	if DirAccess.remove_absolute(to) != OK:
		return false
	return DirAccess.rename_absolute(from, to) == OK

static func _clean(input: Dictionary) -> Dictionary:
	var language := str(input.get("language", "en"))
	var raw_weapons = input.get("weapons", {})
	if not raw_weapons is Dictionary:
		raw_weapons = {}
	var weapons := {}
	for weapon_id in Rules.weapon_ids():
		weapons[weapon_id] = true if weapon_id == "blade" else raw_weapons.get(weapon_id, false) == true
	var equipped := str(input.get("equipped", "blade"))
	if not weapons.get(equipped, false):
		equipped = "blade"
	var completed_hunts: Array[String] = []
	var raw_completed = input.get("completed_hunts", [])
	if raw_completed is Array:
		for id in raw_completed:
			if id is String and not id.is_empty() and id not in completed_hunts:
				completed_hunts.append(id)
	var inventory := {}
	var raw_inventory = input.get("inventory", {})
	if raw_inventory is Dictionary:
		for id in raw_inventory:
			var material_id := str(id)
			if not material_id.is_empty():
				inventory[material_id] = maxi(0, int(raw_inventory[id]))
	var hunt_records := {}
	var raw_records = input.get("hunt_records", {})
	if raw_records is Dictionary:
		for id in raw_records:
			var record = raw_records[id]
			if record is Dictionary and not str(id).is_empty():
				hunt_records[str(id)] = {"wins": maxi(0, int(record.get("wins", 0))), "best_time_ms": maxi(0, int(record.get("best_time_ms", 0)))}
	var raw_bestiary = input.get("bestiary", {})
	var bestiary: Dictionary = raw_bestiary.duplicate(true) if raw_bestiary is Dictionary else {}
	var raw_armor = input.get("armor_owned", {})
	var armor_owned := {}
	if not raw_armor is Dictionary:
		raw_armor = {}
	for id in Rules.coat_ids():
		armor_owned[id] = true if id == "field" else raw_armor.get(id, false) == true
	var armor_equipped := str(input.get("armor_equipped", "field"))
	if not armor_owned.get(armor_equipped, false):
		armor_equipped = "field"
	var raw_settings = input.get("settings", {})
	if not raw_settings is Dictionary:
		raw_settings = {}
	var settings := {
		"music_volume": clampf(float(raw_settings.get("music_volume", 1.0)), 0.0, 1.0),
		"sound_volume": clampf(float(raw_settings.get("sound_volume", 1.0)), 0.0, 1.0),
		"touch_scale": clampf(float(raw_settings.get("touch_scale", 1.0)), 0.8, 1.4),
		"reduced_flash": raw_settings.get("reduced_flash", false) == true
	}
	return {
		"schema_version": SCHEMA_VERSION,
		"language": language if language == "vi" else "en",
		"parts": maxi(0, int(input.get("parts", 0))),
		"forge_level": clampi(int(input.get("forge_level", 0)), 0, 3),
		"hunts_won": maxi(0, int(input.get("hunts_won", 0))),
		"weapons": weapons,
		"equipped": equipped,
		"chapter": clampi(int(input.get("chapter", 1)), 1, 4),
		"completed_hunts": completed_hunts,
		"hunt_records": hunt_records,
		"inventory": inventory,
		"bestiary": bestiary,
		"armor_owned": armor_owned,
		"armor_equipped": armor_equipped,
		"companion_unlocked": input.get("companion_unlocked", false) == true,
		"settings": settings
	}
