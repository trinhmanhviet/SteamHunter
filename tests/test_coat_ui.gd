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
	progress["parts"] = 8
	progress["inventory"] = {"ash_plate": 2, "thorn_antler": 2, "bell_core": 1}
	ui.show_coats(progress)
	await process_frame
	_check(ui.root.get_node_or_null("CoatPanel") != null, "coat crafting has its own panel")
	for coat_id in ["field", "ember", "thorn"]:
		var portrait = ui.root.get_node_or_null("CoatCards/Portrait_" + coat_id)
		var button = ui.root.get_node_or_null("CoatCards/Coat_" + coat_id)
		_check(portrait is Sprite2D and portrait.texture != null, coat_id + " uses its original coat illustration")
		_check(button is Button, coat_id + " has an equip or craft action")
	_check(ui.root.get_node_or_null("OpenWeapons") is Button, "coat page links back to weapons")
	ui.set_language("vi")
	ui.show_coats(progress)
	await process_frame
	_check(ui.root.get_node("CoatCards/Coat_ember").text.contains("MẢNH TRO"), "Vietnamese recipe names the required trophy plainly")
	ui.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
