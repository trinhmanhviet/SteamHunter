extends SceneTree

const Cycle = preload("res://attack_cycle.gd")
var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var c = Cycle.new()
	check(c.press(), "first input must begin raise")
	c.step(10.0)
	check(c.state == "hold", "holding must not auto-strike even after ten seconds")
	check(c.hit_count == 0, "charge must never damage target")
	c.release()
	check(c.state == "strike", "release from overhead must start downswing immediately")
	c.step(0.05)
	check(c.hit_count == 0, "damage must wait for impact")
	c.step(0.05)
	check(c.hit_count == 1, "impact fires once")
	check(c.impact_damage > 100, "charge affects damage")
	c.step(0.5)
	check(c.hit_count == 1, "settle cannot repeatedly damage")
	check(not c.press(), "new input during recovery must not interrupt attack")
	c.step(5.0)
	check(c.state == "ready", "cycle returns to ready")
	c.reset()
	c.press()
	c.release()
	c.step(0.19)
	check(c.state == "raise", "early release must finish raising")
	c.step(0.01)
	check(c.state == "strike", "queued early release starts strike at raise end")
	c.step(.79)
	check(c.state == "recover", "normal swing must finish its recovery before the next attack")
	c.step(.01)
	check(c.state == "ready", "normal swing takes one second")
	check(c.hit_count == 1 and c.impact_damage == 100, "normal swing produces one base hit")
	var fine = Cycle.new()
	fine.press()
	fine.release()
	for i in 120:
		fine.step(1.0 / 120.0)
	check(fine.state == c.state and fine.hit_count == c.hit_count,
		"coarse and fine frame rates must agree")
	c.reset()
	c.press()
	c.release()
	c.step(.2)
	c.step(.067)
	check(c.hit_count == 1, "damage coincides with the ground-contact sprite")
	c.step(.033)
	check(c.hit_count == 1, "strike end cannot repeat the contact hit")
	print("OVERHEAD_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
