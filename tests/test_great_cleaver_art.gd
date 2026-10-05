extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hunter := Hunter.new()
	hunter.weapon_type = "blade"
	root.add_child(hunter)
	_check(hunter.get("blade_sprite") != null, "Great Cleaver hunter owns a separate oversized blade sprite")
	if hunter.get("blade_sprite") != null:
		_check(hunter.blade_sprite.texture.resource_path.ends_with("great_cleaver_poses.png"), "Great Cleaver uses the generated original blade art")
		_check(hunter.blade_sprite.region_enabled and hunter.blade_sprite.region_rect.size.x > 500.0, "Great Cleaver reads a dedicated pose from its sprite strip")
		hunter.start_blade_charge()
		hunter.advance_blade_charge(0.3)
		hunter._update_art(0.0)
		_check(hunter.blade_sprite.region_rect.position.x > 500.0, "charging shifts Great Cleaver to its overhead pose")
		hunter.release_blade_charge()
		hunter.advance_action(0.6)
		hunter._update_art(0.0)
		_check(hunter.blade_sprite.region_rect.position.x > 1000.0, "committed Great Cleaver strike shifts to its cleave pose")
	hunter.queue_free()
	quit(1 if failures > 0 else 0)

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		failures += 1
