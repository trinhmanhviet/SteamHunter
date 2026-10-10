extends SceneTree

const Sweep = preload("res://scripts/blade_sweep.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func target(at: Vector2) -> Array[PackedVector2Array]:
	return [PackedVector2Array([at+Vector2(-1,-1), at+Vector2(1,-1),
		at+Vector2(1,1), at+Vector2(-1,1)])]

func _initialize() -> void:
	# Long blade begins away from the pivot; the grip is not damaging metal.
	var blade := PackedVector2Array([Vector2(30,-2),Vector2(100,-2),Vector2(100,2),Vector2(30,2)])
	var pieces := Sweep.between(blade, Vector2.ZERO, 0, Vector2.ZERO, -PI/2)
	check(Sweep.overlaps(pieces, target(Vector2(70,-70))), "fast arc must hit between its endpoint poses")
	check(not Sweep.overlaps(pieces, target(Vector2(18,-18))), "empty area near the handle must not become a giant fan hitbox")
	check(not Sweep.overlaps(pieces, target(Vector2(76,-76))), "outside the sword tip must miss")
	check(Sweep.overlaps(pieces, target(Vector2(60,0))), "actual starting blade overlap hits")
	var reverse := Sweep.between(blade, Vector2.ZERO, -PI/2, Vector2.ZERO, 0)
	check(Sweep.overlaps(reverse, target(Vector2(70,-70))), "reverse motion uses the same physical contact")
	print("BLADE_SWEEP: 5 checks, %d failures" % failures)
	quit(1 if failures else 0)
