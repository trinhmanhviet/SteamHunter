extends SceneTree

const Beast = preload("res://scripts/cinderback.gd")
var failures := 0

func _initialize() -> void:
	var beast = Beast.new()
	_check(beast.health == beast.max_health, "beast starts at full health")
	beast.receive_hit(30, "heavy")
	beast.receive_hit(30, "heavy")
	_check(beast.armor_broken, "two heavy strikes can break the vent")
	beast.receive_hit(140, "heavy")
	_check(beast.phase == 2, "wounded beast enters faster second phase")
	beast.receive_hit(999, "quick")
	_check(beast.health == 0 and beast.state == "dead", "beast can be defeated")
	var tail_beast = Beast.new()
	_check(tail_beast.has_method("part_status") and tail_beast.has_method("attack_profile"), "Cinderback exposes two target parts and move effects")
	if tail_beast.has_method("part_status") and tail_beast.has_method("attack_profile"):
		_check(tail_beast.part_ids() == ["vent", "tail"], "vent and tail have stable target order")
		tail_beast.receive_hit(50, "heavy", "tail")
		_check(tail_beast.part_status("tail")["wounded"], "tail gains an open wound")
		tail_beast.receive_hit(10, "heavy", "tail")
		_check(tail_beast.state == "recover" and tail_beast.state_time >= 0.9, "wound strike interrupts Cinderback")
		tail_beast.receive_hit(30, "heavy", "tail")
		_check(tail_beast.part_status("tail")["broken"] and not tail_beast.armor_broken, "tail breaks independently of vent")
		_check(tail_beast.attack_profile("sweep")["reach"] < 112.0, "broken tail shortens sweep")
	beast.free()
	tail_beast.free()
	quit(1 if failures > 0 else 0)

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		failures += 1
