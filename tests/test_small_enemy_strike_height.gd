extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	game.save_enabled = false
	root.add_child(game)
	game.start_hunt("moor")
	var rat: Node2D = game.rats[0]
	var start_health: int = game.hunter.health
	rat.position = game.hunter.position + Vector2(28, -54)
	game._on_rat_attack(11, rat)
	_check(game.hunter.health == start_health, "small enemy cannot hurt a hunter standing above it")
	rat.position = game.hunter.position + Vector2(28, 0)
	game._on_rat_attack(11, rat)
	_check(game.hunter.health < start_health, "small enemy hurts only inside its ground-level strike band")
	game.hunter.invincible_time = 0.0
	var grounded_health: int = game.hunter.health
	rat.position = game.hunter.position + Vector2(28, 48)
	game._on_rat_attack(11, rat)
	_check(game.hunter.health == grounded_health, "small enemy cannot hurt a hunter passing over it")
	game.queue_free()
	quit(1 if failures > 0 else 0)

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		failures += 1
