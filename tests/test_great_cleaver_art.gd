extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hunter := Hunter.new()
	hunter.weapon_type = "blade"
	root.add_child(hunter)
	_check(hunter.sprite.texture.resource_path.ends_with("great_cleaver_hunter_spritesheet.png"), "Great Cleaver uses the factory-built hunter pose sheet")
	_check(hunter.sprite.region_enabled, "Great Cleaver hunter art selects one pose from its sprite sheet")
	_check(hunter.sprite.region_rect.size == Vector2(128, 128), "Great Cleaver pose cells retain the native 128px canvas")
	_check(hunter.blade_sprite == null, "Great Cleaver art is a single readable hunter-and-weapon silhouette")
	hunter.start_blade_charge()
	hunter.advance_blade_charge(0.3)
	hunter._update_art(0.0)
	_check(hunter.sprite.region_rect.position.x == 128.0, "charging selects the overhead Great Cleaver pose")
	hunter.release_blade_charge()
	hunter.advance_action(0.6)
	hunter._update_art(0.0)
	_check(hunter.sprite.region_rect.position.x >= 256.0, "committed Great Cleaver strike selects a combat pose")
	hunter.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
