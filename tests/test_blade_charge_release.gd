extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")
const Rules = preload("res://scripts/rules.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var hunter := Hunter.new()
	root.add_child(hunter)
	hunter.set_physics_process(false)
	# A finisher that misses spends Resolve but never reaches confirm_hit().
	hunter.blade_route_index = 2
	hunter.weapon_resource = 1.0
	check(hunter.start_action("sundering_fall"), "funded finisher begins")
	hunter.advance_action(hunter.attack_time + .01)
	check(hunter.weapon_resource == 0 and hunter.blade_route_index == 2,
		"missed finisher reproduces the phone's empty Resolve / third-route state")
	for hold in [.65, 1.0, 2.0]:
		hunter.stamina = hunter.max_stamina
		check(hunter.start_blade_charge(), "standing hold begins after a missed finisher")
		hunter.advance_blade_charge(hold)
		check(hunter.release_blade_charge(), "releasing without Resolve must still produce a cut")
		check(hunter.current_action == "charged_hew", "unavailable finisher falls back to ordinary charged cut")
		check(hunter.charge_time == 0, "release clears the held charge")
		hunter.advance_action(hunter.attack_time + .01)
	# Holding again during the second cut's recovery uses the buffered route too.
	hunter.stamina = hunter.max_stamina
	hunter.weapon_resource = 0
	hunter.start_action("furnace_hew")
	hunter.confirm_hit("furnace_hew")
	hunter.advance_action(float(Rules.action("furnace_hew")["combo_open"]) + .01)
	check(hunter.start_blade_charge(), "charge input is accepted in the follow-up window")
	check(hunter.buffered_token == "charged_hew", "unfunded queued finisher also falls back")
	hunter.advance_action(hunter.attack_time + .01)
	check(hunter.current_action == "charged_hew", "buffered release cannot disappear at recovery end")
	hunter.advance_action(hunter.attack_time + .01)
	# Funded finishers must keep working and pay their original cost once.
	hunter.stamina = hunter.max_stamina
	hunter.blade_route_index = 2
	hunter.weapon_resource = 1.0
	hunter.start_blade_charge()
	hunter.advance_blade_charge(.92)
	check(hunter.release_blade_charge(), "funded third-route charge releases")
	check(hunter.current_action == "sundering_fall" and hunter.weapon_resource == 0,
		"funded finisher remains available and spends Resolve once")
	hunter.queue_free()
	await process_frame
	print("BLADE_CHARGE_RELEASE failures=", failures)
	quit(1 if failures else 0)
