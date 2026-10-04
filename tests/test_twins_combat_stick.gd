extends SceneTree

const TwinsCombatStick = preload("res://scripts/twins_combat_stick.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stick := TwinsCombatStick.new()
	stick.position = Vector2.ZERO
	stick.size = Vector2(960, 540)
	stick.exclusion_rects = [Rect2(646, 330, 66, 66), Rect2(620, 421, 78, 78)]
	root.add_child(stick)
	var commands: Array[String] = []
	stick.twins_command.connect(func(command: String): commands.append(command))
	await process_frame

	_touch(stick, 1, true, Vector2(780, 350))
	_touch(stick, 1, false, Vector2(780, 350))
	_check(commands == ["cut"], "short right-stick release starts the Twin Fangs cut chain")

	_touch(stick, 2, true, Vector2(780, 350))
	_drag(stick, 2, Vector2(780, 280))
	_touch(stick, 2, false, Vector2(780, 280))
	_check(commands.back() == "rush", "upward pull sends the Twin Fangs rush route")

	_touch(stick, 3, true, Vector2(780, 350))
	_drag(stick, 3, Vector2(780, 425))
	_touch(stick, 3, false, Vector2(780, 425))
	_check(commands.back() == "dodge", "quick downward pull sends Twin Fangs dodge")

	_touch(stick, 4, true, Vector2(780, 350))
	stick.advance_hold(0.22)
	_touch(stick, 4, false, Vector2(780, 350))
	_check(commands.back() == "fan", "hold then release sends the retreating fan")

	_touch(stick, 5, true, Vector2(780, 350))
	stick.advance_hold(0.22)
	_drag(stick, 5, Vector2(780, 280))
	_check(commands.back() == "overdrive", "upward sweep during a hold sends Overdrive")
	_touch(stick, 5, false, Vector2(780, 280))
	_check(commands.back() == "overdrive", "Overdrive does not also send retreating fan on release")

	_touch(stick, 6, true, Vector2(680, 360))
	_check(stick.finger_index < 0, "support buttons stay outside the Twin Fangs touch surface")
	stick.queue_free()
	quit()

func _touch(control: Node, finger: int, pressed: bool, at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.pressed = pressed
	event.position = at
	control._input(event)

func _drag(control: Node, finger: int, at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = finger
	event.position = at
	control._input(event)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
