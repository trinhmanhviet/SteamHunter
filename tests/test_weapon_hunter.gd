extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var maul = Hunter.new()
	maul.weapon_type = "maul"
	root.add_child(maul)
	_check(maul.start_attack("quick", 0.0), "maul hunter can begin a strike")
	_check(maul.stamina == 83.0 and is_equal_approx(maul.attack_time, 0.27), "maul uses heavy stamina and slower timing")
	_check(maul.sprite.texture.resource_path.ends_with("hunter_maul.png"), "maul art appears in hunter hands")
	var pike = Hunter.new()
	pike.weapon_type = "pike"
	root.add_child(pike)
	_check(pike.start_attack("heavy", 1.0), "pike hunter can charge")
	_check(pike.stamina == 75.0, "pike has a lower heavy stamina cost")
	_check(pike.sprite.texture.resource_path.ends_with("hunter_pike.png"), "pike art appears in hunter hands")
	pike.facing = -1
	pike._update_art(0.0)
	_check(pike.sprite.position.x < 0.0, "pike body stays centered when facing left")
	maul.queue_free()
	pike.queue_free()
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
