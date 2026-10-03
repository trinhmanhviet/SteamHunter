extends SceneTree

const Rules = preload("res://scripts/rules.gd")

func _initialize() -> void:
	_check(Rules.weapon_ids() == ["blade", "counter", "twins", "pike", "maul"], "four core weapons and legacy maul are available")
	_check(Rules.weapon_cost("counter") == 6 and Rules.weapon_cost("twins") == 6, "new weapons have distinct forge entries")
	_check(Rules.action_ids("blade").size() >= 8 and Rules.action_ids("counter").size() >= 8, "weapon action graphs are exposed through rules")
	_check(Rules.attack_reach("quick", "pike") > Rules.attack_reach("quick", "blade"), "pike reaches farther")
	_check(Rules.attack_damage("heavy", 1.0, 0, "maul") > Rules.attack_damage("heavy", 1.0, 0, "blade"), "maul hits harder")
	_check(Rules.attack_cost("heavy", "maul") > Rules.attack_cost("heavy", "pike"), "maul needs more stamina")
	_check(Rules.attack_duration("heavy", "maul") > Rules.attack_duration("heavy", "pike"), "maul swings slower")
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
