extends SceneTree

const Thornhart = preload("res://scripts/thornhart.gd")
const Boar = preload("res://scripts/bristlehog.gd")
const Catalog = preload("res://scripts/hunt_catalog.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	game.start_hunt("briarwood")
	await physics_frame
	_check(game.selected_hunt == "briarwood", "forest selection remains active")
	var active = game.get("active_hunt")
	_check(active is Dictionary and active == Catalog.get_hunt("briarwood"), "forest uses its catalog record")
	_check(game.boss is Thornhart, "forest spawns Thornhart")
	_check(game.rats.size() > 0 and game.rats[0] is Boar, "forest spawns boars")
	_check(game.boss.get_script() == Catalog.get_hunt("briarwood")["boss_script"], "forest boss comes from its record")
	_check(game.rats[0].get_script() == Catalog.get_hunt("briarwood")["small_script"], "forest small foe comes from its record")
	game.boss.receive_hit(999, "heavy")
	await process_frame
	_check(game.mode == "result", "forest boss defeat ends hunt")
	_check(int(game.progress["parts"]) >= 5, "forest gives a distinct reward")
	_check(game.progress["inventory"].get("thorn_antler", 0) == 2, "broken antlers grant two Thorn Antlers")
	_check("briarwood" in game.progress["completed_hunts"], "forest victory is recorded for story progress")
	_check(game.progress["hunt_records"].get("briarwood", {}).get("wins") == 1, "forest victory increments its own record")
	game.start_hunt()
	await physics_frame
	_check(game.boss is Thornhart, "retry keeps selected forest hunt")
	game.start_hunt("missing")
	await physics_frame
	_check(game.selected_hunt == "briarwood" and game.boss is Thornhart, "unknown hunt cannot replace selected hunt")
	game.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
