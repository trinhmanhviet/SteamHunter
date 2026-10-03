extends SceneTree

const Rules = preload("res://scripts/rules.gd")
const Words = preload("res://scripts/words.gd")

func _initialize() -> void:
	_check(Rules.can_spend_stamina(20.0, 20.0), "exact stamina cost is allowed")
	_check(not Rules.can_spend_stamina(19.0, 20.0), "attack cannot overdraw stamina")
	_check(Rules.attack_damage("quick", 0.0, 0) == 12, "quick strike base damage")
	_check(Rules.attack_damage("heavy", 1.0, 0) > Rules.attack_damage("heavy", 0.0, 0), "charging adds damage")
	_check(Rules.attack_damage("quick", 0.0, 1) > Rules.attack_damage("quick", 0.0, 0), "forging improves attacks")
	_check(Rules.forge_cost(0) == 3, "first forge cost")
	_check(Rules.hunt_reward(true) > Rules.hunt_reward(false), "breaking armor earns an extra part")
	_check(Words.get_text("vi", "title") == "Sương và Sắt", "Vietnamese title")
	_check(Words.get_text("en", "title") == "Mist & Iron", "English title")
	_check(Words.get_text("zz", "title") == "Mist & Iron", "unknown language falls back to English")
	quit()

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		quit(1)
