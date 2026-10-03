extends SceneTree

const Store = preload("res://scripts/save_store.gd")
const TEST_PATH := "res://build/save_store_test.json"
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_cleanup()
	_check(Store.load_progress(TEST_PATH)["parts"] == 0, "missing save starts at defaults")
	var first := Store.defaults()
	first["language"] = "vi"
	first["parts"] = 7
	_check(Store.save_progress(first, TEST_PATH), "first save writes")
	var second := Store.defaults()
	second["language"] = "en"
	second["parts"] = 11
	_check(Store.save_progress(second, TEST_PATH), "second save writes")
	_check(Store.load_progress(TEST_PATH)["parts"] == 11, "main save has latest progress")
	_check(FileAccess.file_exists(TEST_PATH + ".bak"), "previous save is backed up")
	if FileAccess.file_exists(TEST_PATH + ".bak"):
		var backup: Dictionary = Store.decode(FileAccess.get_file_as_string(TEST_PATH + ".bak"))
		_check(backup["parts"] == 7 and backup["language"] == "vi", "backup preserves previous progress")
	var broken := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if broken != null:
		broken.store_string("{broken json")
		broken.close()
	_check(Store.load_progress(TEST_PATH)["parts"] == 7, "corrupt main recovers previous save")
	var recovered := Store.load_progress(TEST_PATH)
	recovered["parts"] = 9
	_check(Store.save_progress(recovered, TEST_PATH), "recovered progress can be saved again")
	_check(Store.load_progress(TEST_PATH)["parts"] == 9, "recovered progress becomes current")
	_check(Store.decode(FileAccess.get_file_as_string(TEST_PATH + ".bak"))["parts"] == 7, "corrupt main never overwrites the healthy backup")
	_cleanup()
	quit(1 if failures > 0 else 0)

func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak", ".bak.tmp"]:
		var path: String = TEST_PATH + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
