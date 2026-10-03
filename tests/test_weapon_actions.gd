extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var blade = _hunter("blade")
	_check(blade.start_action("draw_hew"), "Great Blade can start its draw action")
	_check(blade.stamina == 88.0 and blade.current_action == "draw_hew", "action data controls stamina and active move")
	_check(not blade.request_action("light"), "early input cannot cancel a committed swing")
	blade.advance_action(0.31)
	_check(blade.request_action("light"), "input buffers inside the cancel window")
	blade.advance_action(0.12)
	_check(blade.current_action == "low_cleave", "buffered light begins the declared follow-up")
	_finish(blade)
	_check(blade.start_action("charged_hew", 1.0), "Great Blade starts a fully charged hew")
	var charged_damage: int = blade.current_damage()
	blade.confirm_hit("charged_hew")
	_check(charged_damage > 20 and blade.weapon_resource == 1.0, "full charge gains damage and Resolve on hit")
	_finish(blade)
	_check(blade.start_action("sundering_fall"), "Resolve unlocks Sundering Fall")
	_check(blade.weapon_resource == 0.0, "Sundering Fall spends Resolve")

	var counter = _hunter("counter")
	_check(counter.start_action("counter_guard"), "Counter Blade can open its guard")
	counter.take_hit(24)
	_check(counter.health == 100 and counter.current_action == "counter_riposte", "perfect counter prevents damage and launches riposte")
	counter.confirm_hit("counter_riposte")
	_check(counter.weapon_resource > 0.0, "counter riposte restores Focus on hit")

	var twins = _hunter("twins")
	_check(not twins.start_action("overdrive_flurry"), "Twin Blades need Tempo for Overdrive")
	twins.weapon_resource = 60.0
	_check(twins.start_action("overdrive_flurry"), "Twin Blades spend stored Tempo on Overdrive")
	_check(twins.weapon_resource == 0.0 and twins.attack_time > 0.7, "Overdrive has a committed duration")

	var pike = _hunter("pike")
	_check(pike.weapon_resource == 100.0, "Fortress Lance starts with a full guard meter")
	_check(pike.start_action("guard_set"), "Fortress Lance raises its guard")
	pike.take_hit(20)
	_check(pike.health == 95 and pike.weapon_resource < 100.0, "guard reduces damage and consumes stability")
	_check(pike.current_action == "counter_thrust", "a blocked hit opens Counter Thrust")

	var branches = _hunter("twins")
	_check(branches.request_action("light"), "a sheathed weapon accepts light input")
	_check(branches.current_action == "draw_cross", "first light uses the draw attack")
	_finish(branches)
	branches.start_dodge()
	_check(branches.request_action("light"), "light after dodge starts a branch")
	_check(branches.current_action == "roll_slice", "dodge branch uses Roll Slice")
	_finish(branches)
	_check(branches.request_action("light", false, true), "airborne light starts a branch")
	_check(branches.current_action == "aerial_scissors", "air branch uses Aerial Scissors")

	for hunter in [blade, counter, twins, pike, branches]:
		hunter.queue_free()
	quit()

func _hunter(weapon_id: String):
	var hunter = Hunter.new()
	hunter.weapon_type = weapon_id
	root.add_child(hunter)
	return hunter

func _finish(hunter) -> void:
	hunter.advance_action(hunter.attack_time + 0.01)
	hunter.attack_cooldown = 0.0

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
