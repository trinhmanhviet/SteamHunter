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
	game.start_hunt("moor")
	_check(game.selected_part == "vent", "hunt begins targeting Cinderback vent")
	game.boss.position = game.hunter.position + Vector2(35, 0)
	game.boss.facing = -1
	game.hunter.facing = 1
	game._on_hunter_struck(20, 110.0, "quick")
	_check(int(game.boss.part_status("vent")["progress"]) > 0, "strike reaches selected vent")
	_check(int(game.boss.part_status("tail")["progress"]) == 0, "other part stays intact")
	game.hunter.facing = -1
	game._on_hunter_struck(20, 110.0, "quick")
	_check(int(game.boss.part_status("vent")["progress"]) == 7, "strike facing away cannot hit target")
	game.hunter.facing = 1
	game.cycle_target_part()
	_check(game.selected_part == "tail", "target button cycles to tail")
	_check(game.ui.target_label.text.contains(game.ui.t("part_tail")), "target label shows selected part")
	game._on_hunter_struck(30, 150.0, "heavy")
	_check(int(game.boss.part_status("tail")["progress"]) >= 30, "heavy strike reaches selected tail")
	game.boss.receive_hit(50, "heavy", "tail")
	_check(game.boss.part_status("tail")["broken"], "tail can break in live hunt")
	game.boss.receive_hit(999, "heavy", "vent")
	_check(int(game.progress["parts"]) == Catalog.reward("moor", true, 1), "both broken parts affect victory reward")
	game.queue_free()
	quit(1 if failures > 0 else 0)

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		failures += 1
