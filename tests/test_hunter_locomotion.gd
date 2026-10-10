extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")
const Art = preload("res://scripts/cleaver_art.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func frame_index(hunter) -> int:
	return int(hunter.sprite.region_rect.position.y / 128) * 8 + int(hunter.sprite.region_rect.position.x / 128)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(Art.metadata().has("locomotion"), "Great Cleaver exports running and forward idle assets")
	if failures:
		quit(1)
		return
	var stages: Dictionary = Art.metadata().locomotion
	var hunter := Hunter.new()
	root.add_child(hunter)
	hunter.set_physics_process(false)
	check(frame_index(hunter) == int(stages.idle[0]), "initial standing pose holds the sword pointing forward")
	var idle_angle := float(Art.metadata().frames[int(stages.idle[0])].weapon_angle)
	check(idle_angle < -.5, "reference idle holds the blade diagonally upward")
	check(is_equal_approx(float(Art.metadata().frames[int(Art.metadata().stages.raise[0])].weapon_angle), idle_angle),
		"an overhead cut starts from the same held idle angle")
	check(is_equal_approx(float(Art.metadata().frames[int(Art.metadata().stages.recover[-1])].weapon_angle), idle_angle),
		"overhead recovery returns to the reference held idle")
	var contacts := [0]
	hunter.blade_swept.connect(func(_damage, _kind): contacts[0] += 1)
	hunter.velocity.x = 225
	hunter._update_art(.05)
	var first := frame_index(hunter)
	check(stages.run.has(float(first)), "moving selects an articulated sheathed run cell")
	hunter._update_art(.05)
	check(frame_index(hunter) != first, "actual movement advances the run cycle")
	hunter.facing = -1
	hunter._update_art(.05)
	check(hunter.sprite.flip_h and hunter.blade_sprite.flip_h, "leftward run mirrors body and mounted sword together")
	hunter.velocity.x = 0
	hunter._update_art(.02)
	check(stages.draw.has(float(frame_index(hunter))), "stopping briefly draws the sword from the back")
	hunter._update_art(.20)
	check(frame_index(hunter) == int(stages.idle[0]), "after stopping the sword is held forward")
	hunter._update_art(4)
	check(frame_index(hunter) == int(stages.idle[0]), "long standing never returns to the old rear charge pose")
	check(contacts[0] == 0 and not hunter.blade_damage_active, "running, drawing and idle never cause blade damage")
	hunter.velocity.x = 225
	hunter.start_blade_charge()
	hunter.advance_blade_charge(.65)
	hunter._update_art(.04)
	check(Art.metadata().stages.hold.has(float(frame_index(hunter))), "accepted held charge overrides locomotion")
	check(hunter.release_blade_charge(), "charge after running still releases")
	hunter.advance_action(hunter.attack_emit_at)
	check(frame_index(hunter) == int(Art.metadata().stages.strike[-1]), "combat contact retains the accepted sprite and collider phase")
	var slow := Hunter.new()
	var fast := Hunter.new()
	root.add_child(slow)
	root.add_child(fast)
	slow.set_physics_process(false)
	fast.set_physics_process(false)
	slow.velocity.x = 112.5
	fast.velocity.x = 225
	slow._update_art(.12)
	fast._update_art(.06)
	check(frame_index(slow) == frame_index(fast), "run cadence follows traveled distance at different analog speeds")
	fast.weapon_drawn = true
	fast.global_position = Vector2(500, 0)
	Input.action_press("move_right")
	fast._physics_process(.016)
	Input.action_release("move_right")
	check(is_equal_approx(fast.velocity.x, 225.0), "sword on the back runs at full speed even after prior combat")
	Input.action_press("heavy")
	Input.action_press("move_right")
	fast.start_blade_charge()
	var charge_position := fast.global_position.x
	fast._physics_process(.10)
	check(is_zero_approx(fast.velocity.x) and is_equal_approx(fast.global_position.x, charge_position),
		"holding charge ignores movement input and stops horizontal travel")
	Input.action_release("heavy")
	Input.action_release("move_right")
	slow.queue_free()
	fast.queue_free()
	hunter.queue_free()
	await process_frame
	print("HUNTER_LOCOMOTION failures=", failures)
	quit(1 if failures else 0)
