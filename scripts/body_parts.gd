extends RefCounted

var _states: Dictionary = {}

func _init(definitions: Dictionary) -> void:
	for id in definitions:
		var definition: Dictionary = definitions[id]
		_states[str(id)] = {
			"max": maxi(1, int(definition.get("durability", 1))),
			"progress": 0,
			"wound_at": maxi(1, int(definition.get("wound_at", 45))),
			"wound_progress": 0,
			"wounded": false,
			"broken": false
		}

func ids() -> Array[String]:
	var result: Array[String] = []
	for id in _states:
		result.append(str(id))
	return result

func status(id: String) -> Dictionary:
	if not _states.has(id):
		return {}
	return _states[id].duplicate(true)

func broken_count() -> int:
	var count := 0
	for state in _states.values():
		if state["broken"]:
			count += 1
	return count

func apply_hit(id: String, amount: int, kind: String) -> Dictionary:
	var result := {"valid": false, "broke": false, "wound_opened": false, "stagger": false, "bonus_damage": 0}
	if not _states.has(id):
		return result
	result["valid"] = true
	var state: Dictionary = _states[id]
	if state["broken"]:
		return result
	var safe_amount := maxi(0, amount)
	var part_damage := safe_amount if kind == "heavy" else roundi(safe_amount * 0.35)
	var wound_strike: bool = state["wounded"] and kind == "heavy"
	if wound_strike:
		result["stagger"] = true
		result["bonus_damage"] = roundi(safe_amount * 0.35)
		state["wounded"] = false
		state["wound_progress"] = 0
	state["progress"] = int(state["progress"]) + part_damage
	if int(state["progress"]) >= int(state["max"]):
		state["broken"] = true
		state["wounded"] = false
		state["wound_progress"] = 0
		result["broke"] = true
	elif not wound_strike:
		state["wound_progress"] = int(state["wound_progress"]) + part_damage
		if not state["wounded"] and int(state["wound_progress"]) >= int(state["wound_at"]):
			state["wounded"] = true
			result["wound_opened"] = true
	return result
