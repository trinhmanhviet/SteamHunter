extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	game.start_hunt("briarwood")
	_check(game.herb_sprites.size() == 3 and game.herb_sprites[0].texture != null, "herbs appear as textured sprites")
	game.hunter.potions = 1
	var herb_at: Vector2 = game.herbs[0]
	game.hunter.global_position = herb_at
	game._physics_process(0.016)
	_check(game.hunter.potions == 2, "forest herb adds a drink")
	_check(game.herbs.size() == 2, "collected herb disappears")
	game.queue_free()
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
