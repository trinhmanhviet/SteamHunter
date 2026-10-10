extends RefCounted

var state := "ready"
var elapsed := 0.0
var held := false
var charge_time := 0.0
var hit_count := 0
var impact_damage := 0
var released := false
var impact_fired := false
const LENGTHS := {"raise": 0.20, "strike": 0.10, "settle": 0.22, "recover": 0.48}

func press() -> bool:
	if state != "ready":
		return false
	state = "raise"
	elapsed = 0.0
	held = true
	released = false
	charge_time = 0.0
	impact_fired = false
	return true

func release() -> void:
	held = false
	released = true
	if state == "hold":
		state = "strike"
		elapsed = 0.0

func step(delta: float) -> void:
	var remaining := maxf(delta, 0.0)
	while remaining > 0.000000001 and state != "ready":
		if state == "hold":
			elapsed += remaining
			charge_time += remaining
			return
		var duration: float = LENGTHS[state]
		var consumed := minf(remaining, maxf(0.0, duration - elapsed))
		elapsed += consumed
		remaining -= consumed
		if state == "raise" and held:
			charge_time += consumed
		if state == "strike" and not impact_fired and elapsed + 0.00000001 >= 2.0 / 30.0:
			impact_fired = true
			hit_count += 1
			impact_damage = 100 + 50 * mini(3, int((charge_time + 0.00000001) / 0.8))
		if elapsed + 0.00000001 < duration:
			return
		elapsed = 0.0
		match state:
			"raise": state = "strike" if released else "hold"
			"strike":
				state = "settle"
			"settle": state = "recover"
			"recover": state = "ready"

func reset() -> void:
	state = "ready"
	elapsed = 0.0
	held = false
	charge_time = 0.0
	hit_count = 0
	impact_damage = 0
	released = false
	impact_fired = false
