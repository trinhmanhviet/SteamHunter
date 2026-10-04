extends SceneTree

const Store = preload("res://scripts/save_store.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	game.progress = Store.defaults()
	game.progress["parts"] = 4
	game.progress["inventory"] = {"ash_plate": 2}
	game.open_gear()
	game.open_coats()
	_check(game.mode == "coats" and game.ui.root.get_node_or_null("CoatPanel") != null, "forge opens its separate coat page")
	game.choose_coat("ember")
	_check(game.progress["parts"] == 0 and game.progress["inventory"]["ash_plate"] == 0, "crafting spends iron and the matching trophy")
	_check(game.progress["armor_owned"]["ember"] and game.progress["armor_equipped"] == "ember", "crafted coat becomes owned and equipped")
	game.choose_coat("field")
	game.choose_coat("ember")
	_check(game.progress["parts"] == 0 and game.progress["armor_equipped"] == "ember", "switching owned coats is free")
	game.start_hunt("moor")
	await physics_frame
	_check(game.hunter.armor_type == "ember" and game.hunter.max_health == 125, "equipped coat changes the live hunter")
	game.hunter.take_hit(40)
	_check(game.hunter.health == 91, "ember protection reduces a forty-damage hit to thirty-four")
	game.boss.receive_hit(999, "heavy", "vent")
	await process_frame
	_check(game.progress["inventory"].get("ash_plate", 0) == 2, "broken Cinderback vent grants two ash plates")
	var trophy_label = game.ui.root.get_node_or_null("TrophyRewardLabel")
	_check(trophy_label != null and trophy_label.text.contains("2"), "result screen names and counts the trophy reward")
	game.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
