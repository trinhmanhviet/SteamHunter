extends SceneTree

const GameUI = preload("res://scripts/game_ui.gd")
const Store = preload("res://scripts/save_store.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ui = GameUI.new()
	root.add_child(ui)
	ui.show_hunt_board(Store.defaults())
	await process_frame
	_check(ui.root.get_node_or_null("HuntBoardPanel") != null, "hunt choices open on their own board")
	_check(ui.root.find_children("Hunt_*", "Button", true, false).size() == 3, "all three current hunts are visible without a scrollbar")
	_check(ui.root.find_children("*", "ScrollBar", true, false).is_empty(), "hunt board has no draggable scrollbar")
	ui.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
