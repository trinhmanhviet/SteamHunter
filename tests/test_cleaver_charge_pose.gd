extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")
const Art = preload("res://scripts/cleaver_art.gd")
const Rules = preload("res://scripts/rules.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var hunter := Hunter.new()
	root.add_child(hunter)
	hunter.set_physics_process(false)
	hunter.start_blade_charge()
	hunter.advance_blade_charge(.65)
	var held := Art.frame_for(hunter.blade_charge_visual_time, 0, {}, false)
	var held_angle: float = Art.metadata().frames[held].weapon_angle
	check(cos(held_angle) < -.7, "held charge must keep the sword fully behind the hunter")
	check(hunter.release_blade_charge(), "held rear pose releases a cut")
	hunter.advance_action(.04)
	var action := Rules.action(hunter.current_action)
	var released := Art.frame_for(0, hunter.action_elapsed, action, hunter.blade_attack_from_hold)
	# JSON numeric arrays contain floats; compare the same Variant type.
	check(Art.metadata().stages.get("release", []).has(float(released)),
		"releasing must travel from rear chamber before the downswing, not hold halfway through it")
	check(hunter.action_elapsed < hunter.attack_emit_at, "rear-to-overhead transition precedes impact")
	check(float(Art.metadata().frames[released].weapon_angle) > held_angle,
		"release moves the blade forward from the charged rear pose")
	hunter.advance_action(hunter.attack_emit_at - hunter.action_elapsed)
	check(Art.frame_for(0, hunter.action_elapsed, action, true) == int(Art.metadata().stages.strike[-1]),
		"the declared hit still shows the ground-contact cell")
	hunter.queue_free()
	await process_frame
	print("CLEAVER_CHARGE_POSE failures=", failures)
	quit(1 if failures else 0)
