extends SceneTree

const GameUI = preload("res://scripts/game_ui.gd")
const Store = preload("res://scripts/save_store.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ui = GameUI.new()
	root.add_child(ui)
	var progress := Store.defaults()
	progress["parts"] = 12
	progress["inventory"] = {"ash_plate": 2, "thorn_antler": 2, "bell_core": 2}
	ui.show_tuning(progress)
	await process_frame
	_check(ui.root.get_node_or_null("TuningPanel") != null, "weapon tuning has its own panel")
	_check(ui.root.find_children("Tuning_*", "Button", true, false).size() == 5, "all tuning branches are visible without a scrollbar")
	_check(ui.root.find_children("*", "ScrollBar", true, false).is_empty(), "tuning page exposes no scrollbar")
	_check(ui.root.get_node_or_null("OpenWeapons") is Button, "tuning page returns to weapons")
	ui.set_language("vi")
	ui.show_tuning(progress)
	await process_frame
	_check(ui.root.find_child("Tuning_resonant", true, false).text.contains("LÕI CHUÔNG"), "Vietnamese recipe plainly names Bell Cores")
	ui.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
