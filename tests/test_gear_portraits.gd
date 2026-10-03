extends SceneTree

const GameUI = preload("res://scripts/game_ui.gd")
const Store = preload("res://scripts/save_store.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ui = GameUI.new()
	root.add_child(ui)
	ui.show_gear(Store.defaults())
	_check(ui.root.get_node_or_null("WeaponScroll") is ScrollContainer, "five forge cards live in a horizontal scroller")
	for weapon_id in ["blade", "counter", "twins", "pike", "maul"]:
		var portrait = ui.root.find_child("Portrait_" + weapon_id, true, false)
		_check(portrait is Sprite2D, "gear portrait uses a scaled sprite for " + weapon_id)
		var drawn_size: Vector2 = portrait.texture.get_size() * portrait.scale
		_check(drawn_size.x <= 232.0 and drawn_size.y <= 167.0, "gear portrait fits its card for " + weapon_id)
	ui.queue_free()
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
