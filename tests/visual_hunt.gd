extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	game.start_hunt()
	game.hunter.global_position.x = 2460.0
	game.hunter.get_viewport().get_camera_2d().reset_smoothing()
	for i in range(8):
		await process_frame
	quit()
