extends SceneTree

const GameUI = preload("res://scripts/game_ui.gd")
const Store = preload("res://scripts/save_store.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ui = GameUI.new()
	root.add_child(ui)
	var progress: Dictionary = Store.defaults()
	progress["parts"] = 15
	var pressed: Array[String] = []
	ui.weapon_pressed.connect(func(id: String): pressed.append(id))
	ui.show_gear(progress)
	for weapon_id in ["counter", "twins", "pike", "maul"]:
		var button = ui.root.find_child("Weapon_" + weapon_id, true, false)
		_check(button is Button, "forge has a button for " + weapon_id)
		button.pressed.emit()
	_check(pressed == ["counter", "twins", "pike", "maul"], "each gear card chooses its own weapon")
	ui.queue_free()
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
