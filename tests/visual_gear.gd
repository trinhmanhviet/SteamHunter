extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	game.progress["parts"] = 15
	game.ui.set_language("vi")
	game.open_gear()
	for i in range(6):
		await process_frame
	quit()
