extends SceneTree

const Main = preload("res://scripts/main.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1224, 540)
	get_root().add_child(viewport)
	var game = Main.new()
	game.save_enabled = false
	viewport.add_child(game)
	await process_frame
	var texture_size: Vector2 = game.camp_back.texture.get_size()
	var covered_size: Vector2 = texture_size * game.camp_back.scale
	_check(is_equal_approx(game.camp_back.scale.x, game.camp_back.scale.y), "camp background keeps its aspect ratio")
	_check(covered_size.x >= 1224.0 and covered_size.y >= 540.0, "camp background covers wide viewport")
	_check(game.camp_camera.position == Vector2(612, 270), "camp camera centers on wide viewport")
	viewport.queue_free()
	quit()

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		quit(1)
