extends SceneTree

const BodyParts = preload("res://scripts/body_parts.gd")
var failures := 0

func _initialize() -> void:
	var parts = BodyParts.new({"vent": {"durability": 50, "wound_at": 45}, "tail": {"durability": 80, "wound_at": 45}})
	_check(not parts.apply_hit("wing", 20, "heavy")["valid"], "unknown part is rejected")
	_check(parts.broken_count() == 0, "unknown part changes nothing")
	var quick: Dictionary = parts.apply_hit("vent", 20, "quick")
	_check(quick["valid"] and parts.status("vent")["progress"] == 7, "quick strike adds 35 percent part progress")
	var opened: Dictionary = parts.apply_hit("vent", 40, "heavy")
	_check(opened["wound_opened"] and parts.status("vent")["wounded"], "repeated hits open a wound")
	var broken: Dictionary = parts.apply_hit("vent", 3, "heavy")
	_check(broken["stagger"] and broken["bonus_damage"] == 1, "heavy strike into wound adds damage and stagger")
	_check(broken["broke"] and parts.status("vent")["broken"], "break is reported once")
	_check(not parts.status("vent")["wounded"], "break closes the wound")
	parts.apply_hit("tail", 50, "heavy")
	var tail_break: Dictionary = parts.apply_hit("tail", 40, "heavy")
	_check(tail_break["broke"] and parts.broken_count() == 2, "second part can break independently")
	_check(not parts.apply_hit("tail", 100, "heavy")["broke"], "broken part cannot break twice")
	var snapshot: Dictionary = parts.status("tail")
	snapshot["progress"] = 0
	_check(parts.status("tail")["progress"] >= 80, "status cannot mutate the stored part")
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
