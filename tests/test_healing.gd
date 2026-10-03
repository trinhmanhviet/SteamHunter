extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")

func _initialize() -> void:
	var hunter = Hunter.new()
	hunter.health = 40
	_check(hunter.start_heal(), "wounded hunter can begin drinking")
	_check(not hunter.start_heal(), "hunter cannot begin a second drink while drinking")
	hunter.advance_heal(0.8)
	_check(hunter.health == 75 and hunter.potions == 1, "completed drink heals and consumes one flask")
	hunter.health = 30
	_check(hunter.start_heal(), "hunter can begin another drink")
	hunter.take_hit(10)
	hunter.advance_heal(1.0)
	_check(hunter.health == 20 and hunter.potions == 1, "enemy hit interrupts healing without spending a flask")
	hunter.potions = 2
	hunter.add_potion()
	hunter.add_potion()
	_check(hunter.potions == 3, "gathering respects flask limit")
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
