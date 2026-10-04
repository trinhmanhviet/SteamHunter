extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var blade := Hunter.new()
	blade.weapon_type = "blade"
	root.add_child(blade)

	_check(blade.start_blade_charge(), "Great Cleaver begins a held drag charge")
	blade.advance_blade_charge(0.24)
	_check(blade.blade_charge_stage() == 1, "first held charge reaches the first cut tier")
	blade.advance_blade_charge(0.34)
	_check(blade.blade_charge_stage() == 2, "second held charge reaches the middle cut tier")
	blade.advance_blade_charge(0.33)
	_check(blade.blade_charge_stage() == 3 and blade.charge_time > 0.85, "full hold reaches the final cut tier")
	_check(blade.release_blade_charge(), "releasing the drag commits the charge cut")
	_check(blade.current_action == "charged_hew" and blade.attack_charge == 1.0, "release carries the final tier into the heavy cut")

	_finish(blade)
	_check(blade.start_blade_charge(), "Great Cleaver can charge again after recovering")
	blade.advance_blade_charge(0.35)
	_check(blade.brace_blade_charge(), "downward sweep during a charge starts Brace")
	_check(blade.current_action == "shoulder_brace" and blade.charge_time == 0.0, "Brace cancels charge cleanly")

	_finish(blade)
	_check(blade.start_action("charged_hew", 0.90), "charged cut can begin a Resolve route")
	blade.weapon_resource = 1.0
	blade.advance_action(0.62)
	_check(blade.start_blade_charge(), "holding during the charged-cut window queues the Resolve finisher")
	_check(blade.buffered_token == "sundering_fall", "Great Cleaver routes the held follow-up into Sundering Fall")
	blade.advance_action(0.11)
	_check(blade.current_action == "sundering_fall" and blade.weapon_resource == 0.0, "Resolve finisher consumes Resolve after the charged cut")

	_finish(blade)
	blade.stamina = blade.max_stamina
	_check(blade.start_action("charged_hew", 0.45), "charged cut can enter a defensive follow-up route")
	blade.advance_action(0.62)
	_check(blade.brace_blade_charge(), "downward sweep during charged recovery queues Brace")
	_check(blade.buffered_token == "shoulder_brace", "Brace replaces a pending finisher route")
	blade.advance_action(0.11)
	_check(blade.current_action == "shoulder_brace", "charged recovery flows into Brace")

	blade.queue_free()
	quit()

func _finish(hunter) -> void:
	hunter.advance_action(hunter.attack_time + 0.01)
	hunter.attack_cooldown = 0.0

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
