extends SceneTree

const GameUI = preload("res://scripts/game_ui.gd")
const Hunter = preload("res://scripts/hunter.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(InputMap.has_action("special"), "project exposes the weapon special input")
	var ui = GameUI.new()
	root.add_child(ui)
	ui.show_hunt("moor")
	var special = ui.root.get_node_or_null("Action_special")
	_check(special != null, "hunt HUD has a touch Special button")
	if special != null:
		_check(special.position.x < ui.root.get_node("Action_attack").position.x, "Special stays beside the primary attack cluster")
	var hunter = Hunter.new()
	hunter.weapon_type = "counter"
	root.add_child(hunter)
	ui.update_hud(hunter, null, 0, false)
	_check(ui.resource_label != null and ui.resource_label.text.contains("FOCUS"), "HUD names the equipped weapon resource")
	hunter.weapon_resource = 50.0
	ui.update_hud(hunter, null, 0, false)
	_check(ui.resource_fill != null and is_equal_approx(ui.resource_fill.size.x, 104.0), "resource bar shows half of a 100-point meter")
	if InputMap.has_action("special"):
		Input.action_press("special")
		ui.show_camp({"equipped":"blade", "weapons":{"blade":true}, "parts":0, "forge_level":0, "hunts_won":0})
		_check(not Input.is_action_pressed("special"), "leaving a hunt releases Special")
	hunter.queue_free()
	ui.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
