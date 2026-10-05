extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")
var failures := 0

func _initialize() -> void:
	var hunter := Hunter.new()
	hunter.weapon_type = "blade"
	hunter.facing = 1
	_check(not hunter.can_strike_point(Vector2(90, -132), "low_cleave", 132.0, 0.0, 0.0), "low cleave does not reach its high rising arc")
	_check(hunter.can_strike_point(Vector2(90, -132), "rising_cleave", 142.0, 0.0, 0.0), "rising cleave reaches high targets")
	_check(not hunter.can_strike_point(Vector2(-35, -45), "charged_hew", 150.0, 0.0, 0.0), "charged cleave cannot hit behind the hunter")
	_check(hunter.can_strike_point(Vector2(176, -112), "sundering_fall", 164.0, 18.0, 12.0), "Sundering Fall owns the longest forward hit zone")
	_check(hunter.can_strike_point(Vector2(75, -18), "aerial_drop", 105.0, 0.0, 0.0), "aerial drop reaches the ground below its arc")
	hunter.free()
	quit(1 if failures > 0 else 0)

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		failures += 1
