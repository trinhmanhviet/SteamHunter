extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")

func _initialize() -> void:
	var hunter = Hunter.new()
	_check(hunter.health == 100, "hunter starts healthy")
	hunter.take_hit(20)
	_check(hunter.health == 80, "hunter takes damage")
	hunter.take_hit(20)
	_check(hunter.health == 80, "brief invulnerability stops repeat hit")
	hunter.invincible_time = 0.0
	_check(hunter.start_dodge(), "dodge starts with stamina")
	_check(hunter.stamina == 78.0, "dodge spends 22 stamina")
	_check(hunter.invincible_time > 0.0, "dodge protects hunter")
	hunter.stamina = 0.0
	_check(not hunter.start_attack("quick", 0.0), "strike requires stamina")
	hunter.free()
	quit()

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		quit(1)
