extends SceneTree

const Thornhart = preload("res://scripts/thornhart.gd")
const Boar = preload("res://scripts/bristlehog.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stag = Thornhart.new()
	root.add_child(stag)
	_check(stag.has_method("attack_ids") and stag.attack_ids() == ["charge", "stomp", "thorns"], "Thornhart begins with three readable attacks")
	stag.receive_hit(70, "heavy")
	_check(stag.armor_broken, "heavy strike breaks thorn antlers")
	_check(not "thorns" in stag.attack_ids() and not "briar_lash" in stag.attack_ids(), "broken antlers remove Thornhart's thorn attacks")
	stag.receive_hit(130, "quick")
	_check(stag.phase == 2, "stag enters faster second phase")
	stag.state = "idle"
	stag.advance_state()
	_check(stag.state == "windup", "stag telegraphs attack")
	var hoof_stag = Thornhart.new()
	root.add_child(hoof_stag)
	_check(hoof_stag.has_method("part_status") and hoof_stag.has_method("attack_profile"), "Thornhart exposes two target parts and move effects")
	if hoof_stag.has_method("part_status") and hoof_stag.has_method("attack_profile"):
		_check(hoof_stag.part_ids() == ["antler", "hoof"], "antler and hoof have stable target order")
		hoof_stag.receive_hit(50, "heavy", "hoof")
		hoof_stag.receive_hit(40, "heavy", "hoof")
		_check(hoof_stag.part_status("hoof")["broken"] and not hoof_stag.armor_broken, "hoof breaks independently of antler")
		_check(hoof_stag.attack_profile("charge")["reach"] < 125.0, "broken hoof shortens charge")
		_check(hoof_stag.attack_profile("charge")["speed"] < 320.0, "broken hoof slows charge")
		_check(not "charge" in hoof_stag.attack_ids(), "broken hoof removes the charge from Thornhart's moves")
		hoof_stag.receive_hit(70, "heavy", "antler")
		_check(hoof_stag.state == "knockdown" and hoof_stag.state_time >= 1.5, "breaking both Thornhart parts knocks it down")
		hoof_stag.attack_count = 3
		hoof_stag._finish_attack()
		_check(hoof_stag.state == "exhausted" and hoof_stag.state_time >= 1.2, "Thornhart becomes exhausted after four attack sequences")
	var combo_stag = Thornhart.new()
	root.add_child(combo_stag)
	combo_stag.phase = 2
	combo_stag.attack_count = 2
	combo_stag.state = "strike"
	combo_stag.attack_kind = "charge"
	combo_stag.advance_state()
	_check(combo_stag.state == "combo_wait" and combo_stag.attack_kind == "briar_lash", "intact phase-two Thornhart chains charge into a briar lash")
	var boar = Boar.new()
	root.add_child(boar)
	boar.receive_hit(100)
	_check(boar.health == 0, "boar can be defeated")
	stag.queue_free()
	hoof_stag.queue_free()
	combo_stag.queue_free()
	boar.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
