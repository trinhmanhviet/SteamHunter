extends SceneTree

const Rules = preload("res://scripts/rules.gd")
const Art = preload("res://scripts/cleaver_art.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	var actions := ["draw_hew","low_cleave","rising_cleave","charged_hew","furnace_hew",
		"sundering_fall","anvil_rise","crossbite","roll_reaper","aerial_drop"]
	var reference := Rules.action("draw_hew")
	for id in actions:
		var action := Rules.action(id)
		var after: float = action.duration - action.hit_at
		check(after > .70 and after < .80, id + " recovery must be balanced rather than rushed or prolonged")
		for offset in [.08,.26,.45,.65]:
			check(Art.frame_for(0, action.hit_at + offset, action, false) ==
				Art.frame_for(0, reference.hit_at + offset, reference, false),
				id + " must show the same recovery pose at post-hit %.2f (got %d, expected %d)" % [offset,
				Art.frame_for(0, action.hit_at + offset, action, false),
				Art.frame_for(0, reference.hit_at + offset, reference, false)])
		check(action.combo_open > action.hit_at + .5 and action.combo_open < action.duration,
			id + " buffering must open late without skipping recovery")
	print("CLEAVER_RECOVERY failures=", failures)
	quit(1 if failures else 0)
