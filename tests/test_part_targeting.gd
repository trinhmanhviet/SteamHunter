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
	game.boss.position = game.hunter.position + Vector2(105, 0)
	game.boss.facing = -1
	game.hunter.facing = 1
	_physical_strike(game)
	_check(int(game.boss.part_status("vent")["progress"]) > 0, "strike reaches selected vent")
	_check(int(game.boss.part_status("tail")["progress"]) == 0, "other part stays intact")
	var vent_progress := int(game.boss.part_status("vent")["progress"])
	game.boss.position.x = game.hunter.position.x + 150
	game.hunter.facing = -1
	_physical_strike(game)
	_check(int(game.boss.part_status("vent")["progress"]) == vent_progress, "strike facing away cannot hit target")
	game.hunter.facing = 1
	game.boss.position.x = game.hunter.position.x + 105
	game.cycle_target_part()
	_check(game.selected_part == "tail", "target button cycles to tail")
	_check(game.ui.target_label.text.contains(game.ui.t("part_tail")), "target label shows selected part")
	_physical_strike(game)
	_check(int(game.boss.part_status("tail")["progress"]) > 0, "Great Blade action ID applies heavy part damage")
	_physical_strike(game)
	_check(int(game.boss.part_status("tail")["progress"]) >= 24, "heavy strike reaches selected tail")
	game.boss.receive_hit(80, "heavy", "tail")
	_check(game.boss.part_status("tail")["broken"], "tail can break in live hunt")
	game.boss.receive_hit(999, "heavy", "vent")
	_check(int(game.progress["parts"]) == Catalog.reward("moor", true, 1), "both broken parts affect victory reward")
	game.queue_free()
	quit(1 if failures > 0 else 0)

func _physical_strike(game) -> void:
	var hunter = game.hunter
	hunter.current_action = ""
	hunter.charge_time = 0
	hunter.hit_stop_time = 0
	hunter.stamina = 100
	hunter.start_action("draw_hew")
	hunter.advance_action(hunter.attack_emit_at + .02)

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		failures += 1
