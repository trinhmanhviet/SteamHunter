extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var blade := Hunter.new()
	blade.weapon_type = "blade"
	root.add_child(blade)

	_check(blade.start_blade_charge(), "Great Cleaver begins a held drag charge")
	blade.advance_blade_charge(0.90)
	_check(blade.charge_time > 0.85, "held drag builds a meaningful charge")
	_check(blade.release_blade_charge(), "releasing the drag commits the charge cut")
	_check(blade.current_action == "charged_hew" and blade.attack_charge > 0.70, "release carries the held charge into the heavy cut")

	_finish(blade)
	_check(blade.start_blade_charge(), "Great Cleaver can charge again after recovering")
	blade.advance_blade_charge(0.35)
	_check(blade.brace_blade_charge(), "downward sweep during a charge starts Brace")
	_check(blade.current_action == "shoulder_brace" and blade.charge_time == 0.0, "Brace cancels charge cleanly")

	blade.queue_free()
	quit()

func _finish(hunter) -> void:
	hunter.advance_action(hunter.attack_time + 0.01)
	hunter.attack_cooldown = 0.0

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
