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
	ui.show_hunt("moor", "counter")
	var counter_stick = ui.root.get_node_or_null("CounterCombatStick")
	_check(counter_stick != null and counter_stick.size == ui.root.size, "Warden Sabre gets a full right-side combat stick surface")
	_check(ui.root.get_node_or_null("Action_attack") == null and ui.root.get_node_or_null("Action_heavy") == null and ui.root.get_node_or_null("Action_special") == null and ui.root.get_node_or_null("Action_dodge") == null, "Warden Sabre removes the four combat buttons")
	_check(ui.flash_label.text == ui.t("counter_touch_hint"), "Warden Sabre shows its gesture guide when a hunt begins")
	var hunter = Hunter.new()
	hunter.weapon_type = "counter"
	root.add_child(hunter)
	ui.update_hud(hunter, null, 0, false)
	_check(ui.resource_label != null and ui.resource_label.text.contains("FOCUS"), "HUD names the equipped weapon resource")
	hunter.weapon_resource = 50.0
	ui.update_hud(hunter, null, 0, false)
	_check(ui.resource_fill != null and is_equal_approx(ui.resource_fill.size.x, 104.0), "resource bar shows half of a 100-point meter")
	ui.show_hunt("moor", "blade")
	hunter.weapon_type = "blade"
	hunter.blade_route_index = 2
	ui.update_hud(hunter, null, 0, false)
	var route_pips = ui.root.get_node_or_null("BladeRoutePips")
	_check(route_pips != null and route_pips.get_child_count() == 3, "Great Cleaver HUD has three compact route pips")
	_check(route_pips.get_child(2).modulate == Color("#f1cf89"), "third route pip lights when Sundering Fall is ready")
	ui.show_camp({"equipped":"blade", "weapons":{"blade":true}, "parts":0, "forge_level":0, "hunts_won":0})
	_check(ui.root.get_node_or_null("CounterCombatStick") == null, "leaving a hunt removes the Sabre combat stick")
	ui.show_hunt("moor", "twins")
	var twins_stick = ui.root.get_node_or_null("TwinsCombatStick")
	_check(twins_stick != null and twins_stick.size == ui.root.size, "Twin Fangs gets a full right-side combat stick surface")
	_check(ui.root.get_node_or_null("Action_attack") == null and ui.root.get_node_or_null("Action_heavy") == null and ui.root.get_node_or_null("Action_special") == null and ui.root.get_node_or_null("Action_dodge") == null, "Twin Fangs removes the four combat buttons")
	_check(ui.flash_label.text == ui.t("twins_touch_hint"), "Twin Fangs shows its gesture guide when a hunt begins")
	ui.show_hunt("moor", "pike")
	var pike_stick = ui.root.get_node_or_null("PikeCombatStick")
	_check(pike_stick != null and pike_stick.size == ui.root.size, "Bastion Pike gets a full right-side combat stick surface")
	_check(ui.root.get_node_or_null("Action_attack") == null and ui.root.get_node_or_null("Action_heavy") == null and ui.root.get_node_or_null("Action_special") == null and ui.root.get_node_or_null("Action_dodge") == null, "Bastion Pike removes the four combat buttons")
	_check(ui.flash_label.text == ui.t("pike_touch_hint"), "Bastion Pike shows its gesture guide when a hunt begins")
	hunter.queue_free()
	ui.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
