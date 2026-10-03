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
	for child in ui.root.get_children():
		if child is Button and (child.text == "FORGE · 5 PARTS" or child.text == "FORGE · 7 PARTS"):
			child.pressed.emit()
	_check(pressed == ["pike", "maul"], "each gear card chooses its own weapon")
	ui.queue_free()
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
