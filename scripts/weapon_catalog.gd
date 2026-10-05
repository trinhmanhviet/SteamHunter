extends RefCounted

static var _weapons: Dictionary = {}

static func _a(damage: int, reach: float, duration: float, hit_at: float, combo_open: float, stamina: float, resource_gain: float, resource_cost: float, move: float, impact: String, hit_stop: float, knockback: float, stagger: float, charge_bonus: int = 0) -> Dictionary:
	return {
		"damage": damage,
		"reach": reach,
		"duration": duration,
		"hit_at": hit_at,
		"combo_open": combo_open,
		"stamina": stamina,
		"resource_gain": resource_gain,
		"resource_cost": resource_cost,
		"move": move,
		"impact": impact,
		"hit_stop": hit_stop,
		"knockback": knockback,
		"stagger": stagger,
		"charge_bonus": charge_bonus
	}

static func _ensure() -> void:
	if not _weapons.is_empty():
		return
	_weapons = {
		"blade": {
			"cost": 0, "resource_name": "resolve", "resource_max": 1.0, "resource_start": 0.0,
			"walk_multiplier": 0.72, "art": "res://art/hunter.png", "tint": Color.WHITE,
			"element_scale": 0.70, "status_scale": 0.65,
			"entry": "draw_hew", "light": "low_cleave", "heavy": "charged_hew", "directional": "rising_cleave",
			"dodge": "roll_reaper", "aerial": "aerial_drop", "special": "shoulder_brace",
			"followups": {
				"draw_hew": {"light": "low_cleave", "heavy": "charged_hew"},
				"low_cleave": {"light": "rising_cleave", "heavy": "charged_hew"},
				"rising_cleave": {"heavy": "charged_hew"},
				"charged_hew": {"heavy": "furnace_hew", "special": "shoulder_brace"},
				"furnace_hew": {"heavy": "sundering_fall", "special": "shoulder_brace"},
				"roll_reaper": {"light": "low_cleave"}
			},
			"actions": {
				"draw_hew": _a(12, 125.0, 0.42, 0.20, 0.30, 12.0, 0.0, 0.0, 28.0, "heavy", 0.055, 75.0, 24.0),
				"low_cleave": _a(15, 132.0, 0.48, 0.24, 0.34, 13.0, 0.0, 0.0, 18.0, "heavy", 0.060, 82.0, 28.0),
				"rising_cleave": _a(18, 142.0, 0.56, 0.29, 0.40, 16.0, 0.0, 0.0, 8.0, "heavy", 0.070, 95.0, 34.0),
				"shoulder_brace": _a(7, 78.0, 0.34, 0.18, 0.28, 10.0, 0.0, 0.0, 36.0, "blunt", 0.040, 45.0, 38.0),
				"charged_hew": _a(20, 150.0, 0.72, 0.48, 0.61, 18.0, 0.0, 0.0, 0.0, "heavy", 0.095, 125.0, 52.0, 18),
				"furnace_hew": _a(31, 158.0, 0.80, 0.52, 0.67, 22.0, 0.0, 0.0, 4.0, "heavy", 0.110, 151.0, 67.0, 22),
				"sundering_fall": _a(42, 164.0, 0.88, 0.55, 0.74, 25.0, 0.0, 1.0, 12.0, "heavy", 0.125, 180.0, 82.0),
				"anvil_rise": _a(23, 146.0, 0.66, 0.34, 0.46, 24.0, 0.0, 0.0, 0.0, "heavy", 0.085, 108.0, 46.0),
				"crossbite": _a(28, 136.0, 0.50, 0.24, 0.34, 19.0, 0.0, 0.0, 38.0, "heavy", 0.090, 122.0, 54.0),
				"roll_reaper": _a(14, 118.0, 0.38, 0.18, 0.28, 10.0, 0.0, 0.0, 62.0, "heavy", 0.050, 68.0, 24.0),
				"aerial_drop": _a(24, 105.0, 0.58, 0.31, 0.48, 18.0, 0.0, 0.0, 35.0, "heavy", 0.085, 118.0, 56.0)
			}
		},
		"counter": {
			"cost": 6, "resource_name": "focus", "resource_max": 100.0, "resource_start": 0.0,
			"walk_multiplier": 0.92, "art": "res://art/hunter.png", "tint": Color("#b7d7ff"),
			"element_scale": 1.00, "status_scale": 0.90,
			"entry": "draw_cut", "light": "flow_cut", "heavy": "focus_arc", "directional": "forward_thrust",
			"dodge": "roll_draw", "aerial": "aerial_sweep", "special": "counter_guard",
			"followups": {
				"draw_cut": {"light": "flow_cut", "directional": "forward_thrust"},
				"flow_cut": {"light": "returning_cut", "heavy": "focus_arc"},
				"returning_cut": {"light": "flow_cut", "heavy": "focus_arc", "special": "counter_guard"},
				"forward_thrust": {"light": "flow_cut", "special": "counter_guard"},
				"counter_guard": {"light": "flow_cut"},
				"counter_riposte": {"heavy": "focus_arc"},
				"roll_draw": {"light": "flow_cut"}
			},
			"actions": {
				"draw_cut": _a(10, 138.0, 0.30, 0.13, 0.21, 8.0, 12.0, 0.0, 32.0, "light", 0.035, 42.0, 14.0),
				"flow_cut": _a(11, 145.0, 0.28, 0.12, 0.19, 8.0, 13.0, 0.0, 24.0, "light", 0.035, 45.0, 15.0),
				"returning_cut": _a(14, 154.0, 0.36, 0.17, 0.25, 10.0, 16.0, 0.0, -16.0, "light", 0.045, 58.0, 21.0),
				"forward_thrust": _a(12, 178.0, 0.34, 0.16, 0.25, 10.0, 14.0, 0.0, 74.0, "pierce", 0.040, 52.0, 19.0),
				"focus_arc": _a(31, 168.0, 0.62, 0.36, 0.50, 24.0, 0.0, 40.0, 18.0, "heavy", 0.090, 118.0, 58.0),
				"counter_guard": _a(0, 72.0, 0.52, 0.28, 0.45, 9.0, 0.0, 0.0, 0.0, "light", 0.0, 0.0, 0.0),
				"counter_riposte": _a(34, 182.0, 0.48, 0.20, 0.35, 8.0, 20.0, 0.0, 82.0, "heavy", 0.105, 145.0, 68.0),
				"roll_draw": _a(13, 146.0, 0.32, 0.14, 0.23, 9.0, 12.0, 0.0, 58.0, "light", 0.040, 48.0, 17.0),
				"aerial_sweep": _a(18, 152.0, 0.43, 0.22, 0.34, 13.0, 18.0, 0.0, 25.0, "light", 0.055, 72.0, 29.0)
			}
		},
		"twins": {
			"cost": 6, "resource_name": "tempo", "resource_max": 100.0, "resource_start": 0.0,
			"walk_multiplier": 1.08, "art": "res://art/hunter.png", "tint": Color("#f4b6c8"),
			"element_scale": 1.25, "status_scale": 1.30,
			"entry": "draw_cross", "light": "left_fang", "heavy": "retreating_fan", "directional": "rushing_cross",
			"dodge": "roll_slice", "aerial": "aerial_scissors", "special": "overdrive_flurry",
			"followups": {
				"draw_cross": {"light": "left_fang", "directional": "rushing_cross"},
				"left_fang": {"light": "right_fang", "directional": "rushing_cross"},
				"right_fang": {"light": "wheel_cut", "heavy": "retreating_fan"},
				"wheel_cut": {"light": "left_fang", "heavy": "retreating_fan", "special": "overdrive_flurry"},
				"rushing_cross": {"light": "right_fang"},
				"roll_slice": {"light": "right_fang"},
				"overdrive_flurry": {"heavy": "retreating_fan"}
			},
			"actions": {
				"draw_cross": _a(7, 103.0, 0.22, 0.08, 0.14, 5.0, 10.0, 0.0, 40.0, "light", 0.020, 20.0, 8.0),
				"left_fang": _a(6, 96.0, 0.18, 0.07, 0.12, 4.0, 9.0, 0.0, 28.0, "light", 0.018, 18.0, 7.0),
				"right_fang": _a(7, 101.0, 0.19, 0.07, 0.13, 4.0, 10.0, 0.0, 30.0, "light", 0.020, 20.0, 8.0),
				"wheel_cut": _a(11, 112.0, 0.28, 0.12, 0.19, 7.0, 14.0, 0.0, 12.0, "light", 0.030, 34.0, 13.0),
				"rushing_cross": _a(9, 108.0, 0.25, 0.10, 0.17, 7.0, 11.0, 0.0, 88.0, "light", 0.025, 28.0, 10.0),
				"retreating_fan": _a(15, 124.0, 0.36, 0.16, 0.25, 10.0, 8.0, 0.0, -72.0, "light", 0.040, 52.0, 21.0),
				"roll_slice": _a(8, 99.0, 0.21, 0.08, 0.14, 5.0, 9.0, 0.0, 56.0, "light", 0.020, 22.0, 9.0),
				"aerial_scissors": _a(16, 110.0, 0.34, 0.15, 0.25, 10.0, 15.0, 0.0, 36.0, "light", 0.040, 55.0, 22.0),
				"overdrive_flurry": _a(38, 116.0, 0.78, 0.28, 0.66, 24.0, 0.0, 60.0, 0.0, "light", 0.070, 78.0, 44.0)
			}
		},
		"pike": {
			"cost": 5, "resource_name": "guard", "resource_max": 100.0, "resource_start": 100.0,
			"walk_multiplier": 0.76, "art": "res://art/hunter_pike.png", "tint": Color.WHITE,
			"element_scale": 0.85, "status_scale": 0.80,
			"entry": "draw_thrust", "light": "mid_thrust", "heavy": "shield_bash", "directional": "driving_thrust",
			"dodge": "hop_thrust", "aerial": "high_thrust", "special": "guard_set",
			"followups": {
				"draw_thrust": {"light": "mid_thrust", "directional": "driving_thrust"},
				"mid_thrust": {"light": "high_thrust", "heavy": "shield_bash"},
				"high_thrust": {"light": "mid_thrust", "heavy": "wide_sweep", "special": "guard_set"},
				"driving_thrust": {"light": "mid_thrust", "special": "guard_set"},
				"shield_bash": {"heavy": "wide_sweep", "special": "guard_set"},
				"guard_set": {"light": "counter_thrust"},
				"counter_thrust": {"light": "mid_thrust"},
				"hop_thrust": {"light": "high_thrust"}
			},
			"actions": {
				"draw_thrust": _a(9, 170.0, 0.30, 0.13, 0.21, 9.0, 4.0, 0.0, 34.0, "pierce", 0.032, 38.0, 17.0),
				"mid_thrust": _a(10, 178.0, 0.27, 0.11, 0.19, 8.0, 4.0, 0.0, 12.0, "pierce", 0.032, 40.0, 18.0),
				"high_thrust": _a(12, 184.0, 0.31, 0.13, 0.22, 9.0, 5.0, 0.0, 9.0, "pierce", 0.038, 46.0, 22.0),
				"driving_thrust": _a(15, 205.0, 0.42, 0.20, 0.31, 14.0, 6.0, 0.0, 92.0, "pierce", 0.050, 72.0, 31.0),
				"shield_bash": _a(12, 82.0, 0.34, 0.15, 0.25, 11.0, 8.0, 0.0, 30.0, "blunt", 0.050, 62.0, 46.0),
				"wide_sweep": _a(19, 146.0, 0.52, 0.28, 0.41, 18.0, 8.0, 0.0, 5.0, "heavy", 0.070, 92.0, 40.0),
				"guard_set": _a(0, 72.0, 0.62, 0.31, 0.52, 5.0, 0.0, 0.0, 0.0, "light", 0.0, 0.0, 0.0),
				"counter_thrust": _a(24, 225.0, 0.40, 0.16, 0.29, 9.0, 10.0, 0.0, 66.0, "pierce", 0.075, 105.0, 52.0),
				"hop_thrust": _a(13, 190.0, 0.32, 0.13, 0.23, 10.0, 5.0, 0.0, 58.0, "pierce", 0.042, 55.0, 25.0)
			}
		},
		"maul": {
			"cost": 7, "resource_name": "", "resource_max": 0.0, "resource_start": 0.0,
			"walk_multiplier": 0.68, "art": "res://art/hunter_maul.png", "tint": Color.WHITE,
			"element_scale": 0.55, "status_scale": 0.55,
			"entry": "maul_swing", "light": "maul_swing", "heavy": "maul_crush", "directional": "maul_swing",
			"dodge": "maul_swing", "aerial": "maul_crush", "special": "maul_crush",
			"followups": {"maul_swing": {"light": "maul_swing", "heavy": "maul_crush"}},
			"actions": {
				"maul_swing": _a(16, 94.0, 0.27, 0.14, 0.21, 17.0, 0.0, 0.0, 8.0, "blunt", 0.070, 90.0, 58.0),
				"maul_crush": _a(29, 128.0, 0.46, 0.28, 0.39, 36.0, 0.0, 0.0, 0.0, "blunt", 0.110, 150.0, 88.0, 24)
			}
		}
	}

static func required_ids() -> Array[String]:
	return ["blade", "counter", "twins", "pike"]

static func weapon_ids() -> Array[String]:
	return ["blade", "counter", "twins", "pike", "maul"]

static func weapon(weapon_id: String) -> Dictionary:
	_ensure()
	return _weapons.get(weapon_id, _weapons["blade"])

static func action_ids(weapon_id: String) -> Array[String]:
	var result: Array[String] = []
	for action_id in weapon(weapon_id)["actions"]:
		result.append(str(action_id))
	return result

static func action(weapon_id: String, action_id: String) -> Dictionary:
	var record := weapon(weapon_id)
	return record["actions"].get(action_id, {})
