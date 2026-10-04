extends SceneTree

const AshbellRam = preload("res://scripts/ashbell_ram.gd")
const MireRat = preload("res://scripts/mire_rat.gd")
const Catalog = preload("res://scripts/hunt_catalog.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	game.start_hunt("ashbell")
	await physics_frame
	_check(game.selected_hunt == "ashbell", "third hunt selection remains active")
	_check(game.active_hunt == Catalog.get_hunt("ashbell"), "third hunt uses its catalog record")
	_check(game.boss is AshbellRam, "third hunt spawns Ashbell Ram")
	_check(game.rats.size() == 4 and game.rats[0] is MireRat, "Smoke Moor ecology surrounds Ashbell")
	_check(game.selected_part == "horn", "hunt begins with the visible horn target")
	_check(game.ui.t("ashbell_name") == "ASHBELL RAM", "English boss name is available")
	game.ui.set_language("vi")
	_check(game.ui.t("ashbell_name") == "CỪU CHUÔNG", "Vietnamese boss name is plain and readable")
	game.boss.receive_hit(999, "heavy", "chamber")
	await process_frame
	_check(game.mode == "result", "Ashbell defeat ends the hunt")
	_check(int(game.progress["parts"]) >= 8, "Ashbell and chamber break grant the intended reward")
	_check(game.progress["inventory"].get("bell_core", 0) == 2, "broken chamber grants two Bell Cores")
	_check("ashbell" in game.progress["completed_hunts"], "third hunt completion persists")
	_check(game.progress["hunt_records"].get("ashbell", {}).get("wins") == 1, "third hunt has its own record")
	game.start_hunt()
	await physics_frame
	_check(game.boss is AshbellRam, "retry keeps the selected Ashbell hunt")
	game.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
