extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")
var failures := 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + message)

func run() -> void:
    var hunter = Hunter.new()
    root.add_child(hunter)
    hunter.set_physics_process(false)
    hunter.start_action("draw_hew")
    hunter.action_elapsed = hunter.attack_emit_at
    var polygon: PackedVector2Array = hunter.blade_polygon_at(hunter.action_elapsed)
    var center := Vector2.ZERO
    for point in polygon: center += point
    center /= polygon.size()
    check(hunter.can_strike_point(center, "draw_hew", 125), "point actually on the metal blade hits")
    check(not hunter.can_strike_point(center + Vector2(0,-35), "draw_hew", 999,999,999,999), "legacy padding cannot invent a hit above the blade")
    check(not hunter.can_strike_point(Vector2(500,-20), "draw_hew", 999,999,999,999), "declared reach cannot extend the rendered sword")
    hunter.facing = -1
    check(hunter.can_strike_point(Vector2(-center.x,center.y), "draw_hew", 125), "left-facing collider mirrors exactly")
    check(not hunter.can_strike_point(center, "draw_hew", 999,999,999,999), "opposite-side point cannot hit an unseen blade")
    hunter.queue_free()
    quit(1 if failures else 0)
