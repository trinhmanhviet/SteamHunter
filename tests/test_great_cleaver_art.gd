extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hunter := Hunter.new()
	hunter.weapon_type = "blade"
	root.add_child(hunter)
	_check(hunter.sprite.texture.resource_path.ends_with("body_atlas.png"), "Great Cleaver uses the approved Hunyuan body atlas")
	_check(hunter.sprite.region_enabled, "Great Cleaver hunter art selects one pose from its sprite sheet")
	_check(hunter.sprite.region_rect.size == Vector2(128, 128), "Great Cleaver pose cells retain the native 128px canvas")
	_check(hunter.blade_sprite != null, "Great Cleaver weapon is a separate attachable sprite")
	_check(hunter.blade_sprite.texture.resource_path.ends_with("overhead_atlas.png"), "Great Cleaver uses the matching approved weapon atlas")
	_check(not hunter.sprite.centered and hunter.sprite.offset == Vector2(-64, -116), "body is anchored to its real ground pivot")
	_check(hunter.blade_sprite.offset == Vector2(-192, -244), "weapon shares the same ground pivot in its wider canvas")
	_check(is_equal_approx(hunter.sprite.scale.y * 128, 90), "atlas dimensions cannot shrink the hunter")
	hunter.start_blade_charge()
	hunter.advance_blade_charge(0.3)
	hunter._update_art(0.0)
	_check(hunter.sprite.region_rect.position == Vector2(384, 128), "charge advances the approved overhead holding loop")
	hunter.release_blade_charge()
	hunter.advance_action(hunter.attack_emit_at)
	hunter._update_art(0.0)
	_check(hunter.sprite.region_rect.position == Vector2(768, 256), "hit event selects the actual ground-contact pose")
	hunter.facing = -1
	hunter._update_art(0.0)
	_check(hunter.sprite.flip_h and hunter.blade_sprite.flip_h, "left-facing body and weapon mirror together")
	_check(hunter.sprite.rotation == 0 and hunter.blade_sprite.rotation == 0, "rendered poses are not distorted by a second sprite rotation")
	hunter.advance_action(hunter.attack_time + .01)
	hunter.start_blade_charge()
	hunter.advance_blade_charge(1.3)
	hunter._update_art(0.0)
	var held_pose := hunter.sprite.region_rect
	hunter.advance_blade_charge(.1)
	hunter._update_art(0.0)
	_check(hunter.sprite.region_rect != held_pose, "holding past overcharge continues the breathing animation")
	hunter.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
