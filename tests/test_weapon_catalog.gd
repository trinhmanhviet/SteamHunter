extends SceneTree

const Catalog = preload("res://scripts/weapon_catalog.gd")

const ACTION_FIELDS := [
	"damage", "reach", "duration", "hit_at", "combo_open", "stamina",
	"resource_gain", "resource_cost", "move", "impact", "hit_stop",
	"knockback", "stagger"
]

func _initialize() -> void:
	_check(Catalog.required_ids() == ["blade", "counter", "twins", "pike"], "four representative weapons are required")
	_check(Catalog.weapon_ids() == ["blade", "counter", "twins", "pike", "maul"], "legacy maul remains in the forge")
	for weapon_id in Catalog.required_ids():
		var weapon: Dictionary = Catalog.weapon(weapon_id)
		var actions: Dictionary = weapon.get("actions", {})
		_check(actions.size() >= 8, weapon_id + " has at least eight distinct actions")
		for action_id in actions:
			var action: Dictionary = actions[action_id]
			for field in ACTION_FIELDS:
				_check(action.has(field), weapon_id + "/" + str(action_id) + " has " + field)
			_check(float(action["duration"]) > 0.0, str(action_id) + " has positive duration")
			_check(float(action["hit_at"]) >= 0.0 and float(action["hit_at"]) <= float(action["duration"]), str(action_id) + " hit frame is inside its duration")
			_check(float(action["combo_open"]) >= float(action["hit_at"]) and float(action["combo_open"]) <= float(action["duration"]), str(action_id) + " combo window follows the hit")
			_check(str(action["impact"]) in ["light", "heavy", "pierce", "blunt"], str(action_id) + " uses a supported impact class")
		var followups: Dictionary = weapon.get("followups", {})
		for from_id in followups:
			_check(actions.has(from_id), weapon_id + " follow-up source exists")
			var branches: Dictionary = followups[from_id]
			for token in branches:
				_check(actions.has(branches[token]), weapon_id + " follow-up target exists")
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
