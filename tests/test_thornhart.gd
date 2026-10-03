extends SceneTree

const Thornhart = preload("res://scripts/thornhart.gd")
const Boar = preload("res://scripts/bristlehog.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stag = Thornhart.new()
	root.add_child(stag)
	stag.receive_hit(70, "heavy")
	_check(stag.armor_broken, "heavy strike breaks thorn antlers")
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
	var boar = Boar.new()
	root.add_child(boar)
	boar.receive_hit(100)
	_check(boar.health == 0, "boar can be defeated")
	stag.queue_free()
	hoof_stag.queue_free()
	boar.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
