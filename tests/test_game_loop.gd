extends SceneTree

const Catalog = preload("res://scripts/hunt_catalog.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	_check(game.mode == "camp", "game opens at camp")
	game.start_hunt()
	await physics_frame
	_check(game.mode == "hunt" and game.hunter != null, "hunt starts with a hunter")
	var active = game.get("active_hunt")
	_check(active is Dictionary and active == Catalog.get_hunt("moor"), "moor uses its catalog record")
	_check(game.boss.get_script() == Catalog.get_hunt("moor")["boss_script"], "moor boss comes from its record")
	_check(game.rats[0].get_script() == Catalog.get_hunt("moor")["small_script"], "moor small foe comes from its record")
	game.boss.receive_hit(999, "heavy")
	await process_frame
	_check(game.mode == "result", "defeating boss ends hunt")
	_check(int(game.progress["parts"]) >= 4, "boss awards forging parts")
	_check("moor" in game.progress["completed_hunts"], "moor victory is recorded for story progress")
	_check(game.progress["hunt_records"].get("moor", {}).get("wins") == 1, "moor victory increments its own record")
	game.return_to_camp()
	await process_frame
	_check(game.mode == "camp", "hunter returns to camp")
	game.queue_free()
	quit(1 if failures > 0 else 0)

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		failures += 1
