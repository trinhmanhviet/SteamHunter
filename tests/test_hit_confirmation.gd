extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	game.progress["weapons"]["counter"] = true
	game.progress["equipped"] = "counter"
	game.start_hunt("moor")
	game.boss.position = game.hunter.position + Vector2(35, 0)
	game.boss.facing = -1
	game.hunter.facing = 1
	_check(game.hunter.start_action("draw_cut"), "counter weapon begins a live action")
	game.hunter.advance_action(0.14)
	_check(game.hunter.weapon_resource == 12.0, "a landed action grants its resource once")
	game.hunter.confirm_hit("draw_cut")
	_check(game.hunter.weapon_resource == 12.0, "one swing cannot gain resource twice")
	game.hunter.advance_action(1.0)
	game.hunter.attack_cooldown = 0.0
	game.boss.position.x += 1200.0
	for rat in game.rats:
		rat.position.x += 1200.0
	_check(game.hunter.start_action("flow_cut"), "a second live action starts")
	game.hunter.advance_action(0.13)
	_check(game.hunter.weapon_resource == 12.0, "a missed action grants no resource")
	game.queue_free()
	quit(1 if failures > 0 else 0)

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		failures += 1
