extends SceneTree

const Joystick = preload("res://scripts/virtual_joystick.gd")
const ActionButton = preload("res://scripts/touch_action_button.gd")
const GameUI = preload("res://scripts/game_ui.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stick = Joystick.new()
	stick.position = Vector2.ZERO
	stick.size = Vector2(960, 540)
	get_root().add_child(stick)
	await process_frame
	_check(not stick.visible, "floating stick is hidden while idle")
	_touch(stick, 3, true, Vector2(120, 180))
	_check(stick.finger_index < 0, "touch above activation zone is ignored")
	_touch(stick, 3, true, Vector2(600, 430))
	_check(stick.finger_index < 0, "touch outside left activation zone is ignored")
	_touch(stick, 4, true, Vector2(105, 425))
	_check(stick.visible and stick.finger_index == 4, "valid lower-left touch reveals and owns stick")
	_check(stick.visual_center.distance_to(Vector2(105, 425)) < 0.1, "stick appears at an unclamped touch")
	_drag(stick, 4, Vector2(143, 425))
	_check(Input.get_action_strength("move_right") > 0.45 and Input.get_action_strength("move_right") < 0.65, "stick has proportional rightward strength")
	_touch(stick, 5, true, Vector2(105, 425))
	_drag(stick, 5, Vector2(35, 425))
	_check(Input.get_action_strength("move_right") > 0.45, "another finger cannot steal stick")
	_drag(stick, 4, Vector2(105, 425))
	_check(Input.get_axis("move_left", "move_right") == 0.0, "center dead zone clears movement")
	_drag(stick, 4, Vector2(35, 425))
	_check(Input.get_action_strength("move_left") > 0.85, "left edge gives full speed")
	_touch(stick, 4, false, Vector2(35, 425))
	_check(Input.get_axis("move_left", "move_right") == 0.0, "release clears movement")
	_check(not stick.visible, "release hides floating stick")
	_touch(stick, 6, true, Vector2(4, 536))
	_check(stick.visual_center.x >= stick.visual_radius and stick.visual_center.y <= 540.0 - stick.visual_radius, "stick center clamps inside lower-left zone")
	_touch(stick, 6, false, Vector2(4, 536))
	stick.queue_free()

	var button = ActionButton.new()
	button.action = "heavy"
	button.position = Vector2(700, 300)
	button.size = Vector2(90, 90)
	get_root().add_child(button)
	_touch(button, 7, true, Vector2(745, 345))
	_check(Input.is_action_pressed("heavy"), "button holds action")
	_touch(button, 8, false, Vector2(745, 345))
	_check(Input.is_action_pressed("heavy"), "another finger cannot release button")
	_touch(button, 7, false, Vector2(900, 500))
	_check(not Input.is_action_pressed("heavy"), "release clears held action outside button")
	button.queue_free()

	var ui = GameUI.new()
	get_root().add_child(ui)
	ui.show_hunt("moor")
	var hunt_stick = ui.root.get_node("MoveStick")
	var attack = ui.root.get_node("Action_attack")
	var heavy = ui.root.get_node("Action_heavy")
	var special = ui.root.get_node_or_null("Action_special")
	var jump = ui.root.get_node("Action_jump")
	var dodge = ui.root.get_node("Action_dodge")
	_check(hunt_stick.position == Vector2.ZERO and hunt_stick.size == ui.root.size, "joystick touch surface covers hunt viewport")
	_check(attack.position.x > heavy.position.x and attack.position.x > jump.position.x, "large attack is at right")
	_check(attack.size.x > heavy.size.x and attack.size.x > dodge.size.x, "attack is largest action")
	_check(special != null and special.position.x < attack.position.x, "weapon Special joins the right action cluster")
	_touch(hunt_stick, 1, true, Vector2(105, 425))
	_drag(hunt_stick, 1, Vector2(160, 425))
	_touch(attack, 2, true, attack.position + attack.size / 2.0)
	_check(Input.get_action_strength("move_right") > 0.0 and Input.is_action_pressed("attack"), "move and strike work together")
	ui.show_camp({"equipped":"blade", "weapons":{"blade":true,"pike":false,"maul":false}, "parts":0, "forge_level":0})
	_check(Input.get_axis("move_left", "move_right") == 0.0 and not Input.is_action_pressed("attack"), "leaving hunt clears held controls")
	var regular_camp_panel = ui.root.get_node_or_null("CampMenuPanel")
	_check(regular_camp_panel != null and regular_camp_panel.position.x == 626.0, "16:9 camp panel keeps approved position")
	ui.queue_free()

	var wide_viewport := SubViewport.new()
	wide_viewport.size = Vector2i(1224, 540)
	get_root().add_child(wide_viewport)
	var wide_ui = GameUI.new()
	wide_viewport.add_child(wide_ui)
	wide_ui.show_hunt("moor")
	var wide_stick = wide_ui.root.get_node("MoveStick")
	var wide_attack = wide_ui.root.get_node("Action_attack")
	var wide_pause = wide_ui.root.get_node_or_null("PauseButton")
	var wide_hud = wide_ui.root.get_node_or_null("HuntHud")
	_check(wide_ui.root.size == Vector2(1224, 540), "wide hunt root uses visible viewport size")
	_check(wide_stick.size == Vector2(1224, 540), "wide stick touch surface fills viewport")
	_check(wide_attack.position.x == 1075.0, "attack stays attached to wide right edge")
	_check(wide_pause != null and wide_pause.position.x == 1163.0, "pause stays attached to wide right edge")
	_check(wide_hud != null and wide_hud.position.x == 18.0, "hunt HUD stays attached to left edge")
	_check(wide_ui.boss_group.position.x == 491.0, "boss display follows wide viewport center")
	_check(wide_ui.flash_label.position.x == 462.0, "hunt message follows wide viewport center")

	var wide_progress := {"equipped":"blade", "weapons":{"blade":true,"pike":false,"maul":false}, "parts":0, "forge_level":0, "hunts_won":0}
	wide_ui.show_camp(wide_progress)
	var wide_camp_panel = wide_ui.root.get_node_or_null("CampMenuPanel")
	var wide_camp_title = wide_ui.root.get_node_or_null("CampTitle")
	_check(wide_camp_panel != null and wide_camp_panel.position.x == 890.0, "camp selection stays attached to wide right edge")
	_check(wide_camp_title != null and wide_camp_title.position.x == 450.0, "camp title follows wide viewport center")

	wide_ui.show_gear(wide_progress)
	var wide_gear_panel = wide_ui.root.get_node_or_null("GearPanel")
	_check(wide_gear_panel != null and wide_gear_panel.position.x == 162.0, "forge panel stays centered on wide viewport")

	wide_ui.show_hunt("moor")
	wide_ui._show_pause()
	var wide_pause_panel = wide_ui.root.get_node_or_null("PausePanel")
	_check(wide_pause_panel != null and wide_pause_panel.position.x == 444.0, "pause dialog stays centered on wide viewport")
	paused = false

	wide_ui.show_result(false, 0)
	var wide_result_panel = wide_ui.root.get_node_or_null("ResultPanel")
	_check(wide_result_panel != null and wide_result_panel.position.x == 370.0, "result dialog stays centered on wide viewport")
	wide_viewport.queue_free()
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

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		quit(1)
