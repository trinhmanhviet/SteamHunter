extends SceneTree

const Store = preload("res://scripts/save_store.gd")
const Catalog = preload("res://scripts/hunt_catalog.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	game.progress = Store.defaults()
	game.progress["parts"] = 3
	game.progress["inventory"] = {"ash_plate": 2}
	game.open_gear()
	game.open_tuning()
	_check(game.mode == "tuning" and game.ui.root.get_node_or_null("TuningPanel") != null, "forge opens a separate tuning page")
	game.choose_tuning("ember")
	_check(game.progress["parts"] == 0 and game.progress["inventory"]["ash_plate"] == 0, "ember tuning spends its recipe")
	_check(game.progress["weapon_tunings"]["blade"]["ember"] and game.progress["tuning_equipped"]["blade"] == "ember", "crafted tuning is owned and equipped")
	game.choose_tuning("plain")
	game.choose_tuning("ember")
	_check(game.progress["parts"] == 0 and game.progress["tuning_equipped"]["blade"] == "ember", "owned tuning can be switched freely")
	game.start_hunt("briarwood")
	await physics_frame
	_check(game.hunter.tuning_type == "ember", "selected weapon tuning enters the hunt")
	_check(game._tuned_damage_for_boss(20) > 20, "live Thornhart hit gains heat damage")
	game.return_to_camp()

	game.progress["weapon_tunings"]["blade"]["briar"] = true
	game.progress["tuning_equipped"]["blade"] = "briar"
	game.start_hunt("ashbell")
	await physics_frame
	var threshold := Catalog.status_threshold("ashbell", "snare")
	game.boss_status_buildup = threshold - 1.0
	_check(game._apply_tuning_status(), "briar buildup triggers snare at the monster threshold")
	_check(game.boss.state == "recover" and game.boss.state_time >= 1.2, "snare creates a punishable monster stagger")
	_check(game.boss_status_buildup == 0.0, "status meter resets after proc")
	game.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
