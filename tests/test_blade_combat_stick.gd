extends SceneTree

const BladeCombatStick = preload("res://scripts/blade_combat_stick.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stick := BladeCombatStick.new()
	stick.position = Vector2.ZERO
	stick.size = Vector2(960, 540)
	stick.exclusion_rects = [Rect2(646, 330, 66, 66), Rect2(620, 421, 78, 78)]
	root.add_child(stick)
	var commands: Array[String] = []
	stick.blade_command.connect(func(command: String): commands.append(command))
	await process_frame

	_touch(stick, 1, true, Vector2(780, 350))
	_check(stick.visible and stick.finger_index == 1, "right combat stick appears for a valid right-zone touch")
	_touch(stick, 1, false, Vector2(780, 350))
	_check(commands == ["cut"], "short release sends one cut")
	_touch(stick, 9, true, Vector2(680, 360))
	_check(stick.finger_index < 0, "support buttons inside the right zone do not trigger the combat stick")

	_touch(stick, 2, true, Vector2(780, 350))
	_drag(stick, 2, Vector2(780, 422))
	_touch(stick, 2, false, Vector2(780, 422))
	_check(commands.back() == "dodge", "quick downward pull sends dodge")

	_touch(stick, 3, true, Vector2(780, 350))
	stick.advance_hold(0.22)
	_check(commands.back() == "charge_start", "holding the combat stick starts a charge")
	_check(Input.is_action_pressed("heavy"), "held combat stick keeps the charge input active")
	stick._process(0.36)
	_check(stick.charge_visual_time >= 0.36, "charge ring keeps filling while the finger is held")
	_drag(stick, 3, Vector2(780, 421))
	_check(commands.back() == "brace", "downward sweep during a charge sends Brace")
	_check(not Input.is_action_pressed("heavy"), "Brace releases the held charge input")
	_touch(stick, 3, false, Vector2(780, 421))
	_check(commands.back() == "brace", "a braced charge does not also release a heavy cut")

	_touch(stick, 4, true, Vector2(780, 350))
	stick.advance_hold(0.22)
	_touch(stick, 4, false, Vector2(780, 350))
	_check(commands.back() == "charge_release", "releasing a held combat stick sends the charged cut")
	_check(not Input.is_action_pressed("heavy"), "release clears the held charge input")

	_touch(stick, 5, true, Vector2(780, 350))
	stick.advance_hold(0.22)
	_drag(stick, 5, Vector2(780, 278))
	var commands_before_wait := commands.size()
	stick.advance_hold(0.30)
	_check(commands.size() == commands_before_wait, "primed Anvil Rise does not restart a charge while held")
	_touch(stick, 5, false, Vector2(780, 278))
	_check(commands.back() == "anvil_rise", "held upward pull sends Anvil Rise")
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
