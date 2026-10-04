extends SceneTree

const GameUI = preload("res://scripts/game_ui.gd")
const Store = preload("res://scripts/save_store.gd")
const Catalog = preload("res://scripts/hunt_catalog.gd")
const Words = preload("res://scripts/words.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ui := GameUI.new()
	root.add_child(ui)
	var selected: Array[String] = []
	ui.hunt_pressed.connect(func(id: String): selected.append(id))
	for language in ["en", "vi"]:
		ui.set_language(language)
		ui.show_camp(Store.defaults())
		await process_frame
		_check(ui.root.get_node_or_null("OpenHuntBoard") is Button, language + " camp exposes a hunt-board entrance")
		_check(ui.root.get_node_or_null("OpenForge") is Button, language + " camp exposes a separate forge entrance")
		_check(ui.root.find_child("Hunt_moor", true, false) == null, language + " camp does not mix hunt cards into its service menu")
		ui.show_hunt_board(Store.defaults())
		await process_frame
		for id in Catalog.ids():
			var button: Button = ui.root.find_child("Hunt_" + id, true, false)
			_check(button != null, language + " camp lists " + id)
			if button != null:
				var hunt: Dictionary = Catalog.get_hunt(id)
				_check(button.text.contains(Words.get_text(language, hunt["hunt_name_key"])), language + " uses catalog hunt text")
				button.pressed.emit()
	_check(selected == ["moor", "briarwood", "ashbell", "moor", "briarwood", "ashbell"], "camp buttons send stable catalog IDs")
	ui.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
