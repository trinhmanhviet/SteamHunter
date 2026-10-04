extends SceneTree

const CounterCombatStick = preload("res://scripts/counter_combat_stick.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stick := CounterCombatStick.new()
	stick.position = Vector2.ZERO
	stick.size = Vector2(960, 540)
	stick.exclusion_rects = [Rect2(646, 330, 66, 66), Rect2(620, 421, 78, 78)]
	root.add_child(stick)
	var commands: Array[String] = []
	stick.counter_command.connect(func(command: String): commands.append(command))
	await process_frame

	_touch(stick, 1, true, Vector2(780, 350))
	_touch(stick, 1, false, Vector2(780, 350))
	_check(commands == ["cut"], "short right-stick release sends a Sabre cut")

	_touch(stick, 2, true, Vector2(780, 350))
	_drag(stick, 2, Vector2(780, 280))
	_touch(stick, 2, false, Vector2(780, 280))
	_check(commands.back() == "lift", "upward pull sends the Sabre thrust route")

	_touch(stick, 3, true, Vector2(780, 350))
	_drag(stick, 3, Vector2(780, 425))
	_touch(stick, 3, false, Vector2(780, 425))
	_check(commands.back() == "dodge", "quick downward pull sends dodge")

	_touch(stick, 4, true, Vector2(780, 350))
	stick.advance_hold(0.22)
	_touch(stick, 4, false, Vector2(780, 350))
	_check(commands.back() == "focus_arc", "hold then release sends the Focus Arc")

	_touch(stick, 5, true, Vector2(780, 350))
	stick.advance_hold(0.22)
	_drag(stick, 5, Vector2(780, 425))
	_check(commands.back() == "counter_guard", "downward sweep during a hold opens Counter Guard")
	_touch(stick, 5, false, Vector2(780, 425))
	_check(commands.back() == "counter_guard", "Counter Guard does not also send Focus Arc on release")

	_touch(stick, 6, true, Vector2(680, 360))
	_check(stick.finger_index < 0, "support buttons stay outside the Sabre touch surface")
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
