extends SceneTree

const Rules = preload("res://scripts/rules.gd")

func _initialize() -> void:
	_check(Rules.weapon_ids() == ["blade", "pike", "maul"], "three weapon types are available")
	_check(Rules.weapon_cost("pike") == 5 and Rules.weapon_cost("maul") == 7, "new weapons have distinct part costs")
	_check(Rules.attack_reach("quick", "pike") > Rules.attack_reach("quick", "blade"), "pike reaches farther")
	_check(Rules.attack_damage("heavy", 1.0, 0, "maul") > Rules.attack_damage("heavy", 1.0, 0, "blade"), "maul hits harder")
	_check(Rules.attack_cost("heavy", "maul") > Rules.attack_cost("heavy", "pike"), "maul needs more stamina")
	_check(Rules.attack_duration("heavy", "maul") > Rules.attack_duration("heavy", "pike"), "maul swings slower")
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
