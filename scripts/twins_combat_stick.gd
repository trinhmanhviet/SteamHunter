extends Control

signal twins_command(command: String)

const PULL_DISTANCE := 48.0
const HOLD_TO_FAN := 0.18
const BASE_COLOR := Color(0.15, 0.08, 0.16, 0.72)
const RIM_COLOR := Color(0.96, 0.55, 0.72, 0.92)
const KNOB_COLOR := Color(0.46, 0.18, 0.33, 0.94)

var activation_width_ratio := 0.43
var activation_height_ratio := 0.70
var exclusion_rects: Array[Rect2] = []
var visual_radius := 70.0
var visual_center := Vector2.ZERO
var finger_index := -1
var pull := Vector2.ZERO
var held_time := 0.0
var overdriving := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	queue_redraw()

func _process(delta: float) -> void:
	advance_hold(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger_index < 0 and _can_start_at(_to_local(event.position)):
			finger_index = event.index
			visual_center = _clamp_center(_to_local(event.position))
			pull = Vector2.ZERO
			held_time = 0.0
			overdriving = false
			visible = true
			queue_redraw()
		elif not event.pressed and event.index == finger_index:
			_finish_gesture()
	elif event is InputEventScreenDrag and event.index == finger_index:
		pull = (_to_local(event.position) - visual_center).limit_length(visual_radius)
		if held_time >= HOLD_TO_FAN and not overdriving and pull.y <= -PULL_DISTANCE:
			overdriving = true
			twins_command.emit("overdrive")
		queue_redraw()

func advance_hold(delta: float) -> void:
	if finger_index < 0 or overdriving or delta <= 0.0:
		return
	held_time += delta
	queue_redraw()

func release_touch() -> void:
	finger_index = -1
	pull = Vector2.ZERO
	held_time = 0.0
	overdriving = false
	visible = false
	queue_redraw()

func _finish_gesture() -> void:
	if overdriving:
		pass
	elif held_time >= HOLD_TO_FAN:
		twins_command.emit("fan")
	elif pull.y >= PULL_DISTANCE:
		twins_command.emit("dodge")
	elif pull.y <= -PULL_DISTANCE:
		twins_command.emit("rush")
	else:
		twins_command.emit("cut")
	release_touch()

func _exit_tree() -> void:
	release_touch()

func _to_local(screen_position: Vector2) -> Vector2:
	return screen_position - global_position

func _activation_rect() -> Rect2:
	var zone_size := Vector2(size.x * activation_width_ratio, size.y * activation_height_ratio)
	return Rect2(Vector2(size.x - zone_size.x, size.y - zone_size.y), zone_size)

func _can_start_at(point: Vector2) -> bool:
	if not _activation_rect().has_point(point):
		return false
	for exclusion in exclusion_rects:
		if exclusion.has_point(point):
			return false
	return true

func _clamp_center(point: Vector2) -> Vector2:
	var zone := _activation_rect()
	return Vector2(
		clampf(point.x, zone.position.x + visual_radius, zone.end.x - visual_radius),
		clampf(point.y, zone.position.y + visual_radius, zone.end.y - visual_radius)
	)

func _draw() -> void:
	if not visible:
		return
	draw_circle(visual_center, visual_radius, BASE_COLOR)
	draw_arc(visual_center, visual_radius, 0.0, TAU, 48, RIM_COLOR, 3.0, true)
	draw_arc(visual_center, visual_radius * 0.67, 0.0, TAU, 40, Color(1.0, 0.72, 0.88, 0.22), 1.5, true)
	if held_time >= HOLD_TO_FAN:
		var fan_ratio := clampf((held_time - HOLD_TO_FAN) / 0.72, 0.0, 1.0)
		draw_arc(visual_center, visual_radius * 0.82, -PI * 0.5, -PI * 0.5 + TAU * fan_ratio, 32, Color("#ff9ac1"), 5.0, true)
	var knob_center := visual_center + pull * 0.66
	draw_circle(knob_center, visual_radius * 0.42, Color(0.02, 0.05, 0.08, 0.75))
	draw_circle(knob_center, visual_radius * 0.35, Color("#874762") if held_time >= HOLD_TO_FAN else KNOB_COLOR)
	draw_arc(knob_center, visual_radius * 0.35, 0.0, TAU, 32, RIM_COLOR, 2.0, true)
