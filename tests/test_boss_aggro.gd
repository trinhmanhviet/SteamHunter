extends SceneTree

const Cinderback = preload("res://scripts/cinderback.gd")
const Thornhart = preload("res://scripts/thornhart.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hunter := Node2D.new()
	hunter.position = Vector2(250, 420)
	root.add_child(hunter)
	for boss_script in [Cinderback, Thornhart]:
		var beast = boss_script.new()
		beast.position = Vector2(2700, 420)
		beast.target = hunter
		root.add_child(beast)
		var start_time: float = beast.state_time
		beast._physics_process(1.0)
		_check(beast.position.x == 2700.0, "distant beast waits at its encounter")
		_check(beast.state == "idle" and beast.state_time == start_time, "distant beast does not advance its attacks")
		hunter.position.x = 2200.0
		beast._physics_process(1.0)
		_check(beast.position.x < 2700.0, "nearby hunter wakes beast")
		beast.queue_free()
		hunter.position.x = 250.0
	hunter.queue_free()
	quit(1 if failures > 0 else 0)

func _check(value: bool, message: String) -> void:
	if not value:
		printerr("FAIL: " + message)
		failures += 1
