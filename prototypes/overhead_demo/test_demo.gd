extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func touch(point: Vector2, id: int, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.index = id
	event.pressed = pressed
	return event

func run() -> void:
	var demo = load("res://main.tscn").instantiate()
	root.add_child(demo)
	await process_frame
	demo.set_process(false)
	check(demo.manifest.frames.size() == 74, "all rendered frames must load")
	for frame in demo.manifest.frames:
		for layer in ["body", "weapon"]:
			var region: Array = frame[layer]
			var atlas: Texture2D = demo.get(layer)
			check(region[0] + region[2] <= atlas.get_width() and
				region[1] + region[3] <= atlas.get_height(), "atlas region must fit")
	var size := root.get_visible_rect().size
	var point := Vector2(size.x * .82, size.y * .75)
	demo._input(touch(Vector2(50, 200), 4, true))
	check(demo.cycle.state == "ready", "outside the attack region cannot charge")
	demo._input(touch(point, 4, true))
	check(demo.cycle.state == "raise" and demo.touch_id == 4, "touch starts attack and floating stick")
	check(demo.stick_origin == point, "stick must appear at actual touch origin")
	demo._input(touch(point, 5, false))
	check(demo.cycle.held, "unrelated finger release cannot release charge")
	demo.cycle.step(2.4)
	demo.apply_impact()
	check(demo.cycle.state == "hold" and demo.damage_total == 0, "hold causes no damage")
	demo._input(touch(point, 4, false))
	check(demo.touch_id == -1 and demo.cycle.state == "strike", "release hides stick and cuts")
	demo.cycle.step(.1)
	demo.apply_impact()
	check(demo.damage_total == 250 and demo.hit_seen == 1, "full charge hits practice target")
	demo.apply_impact()
	check(demo.damage_total == 250, "target hit is consumed once")
	demo.cycle.step(1.7)
	check(demo.cycle.state == "ready", "recovery permits next attack")
	demo._input(touch(demo.buttons()[2].get_center(), 6, true))
	check(demo.damage_total == 0 and demo.hit_seen == 0, "reset clears target and cycle")
	demo._input(touch(point, 7, true))
	demo._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not demo.cycle.held and demo.touch_id == -1, "focus loss cannot leave a stuck charge")
	demo.cycle.reset()
	demo._input(touch(demo.buttons()[0].get_center(), 8, true))
	var emulated := InputEventMouseButton.new()
	emulated.device = -1
	emulated.button_index = MOUSE_BUTTON_LEFT
	emulated.pressed = true
	emulated.position = demo.buttons()[0].get_center()
	demo._input(emulated)
	check(demo.automatic, "touch plus its emulated mouse event must toggle once")
	print("OVERHEAD_UI_TESTS: %d checks, %d failures" % [checks, failures])
	demo.queue_free()
	quit(1 if failures else 0)
