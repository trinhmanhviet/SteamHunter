extends Control

const DEAD_ZONE := 0.16
const BASE_COLOR := Color(0.07, 0.14, 0.17, 0.69)
const RIM_COLOR := Color(0.75, 0.59, 0.35, 0.86)
const KNOB_COLOR := Color(0.25, 0.39, 0.42, 0.92)

var activation_width_ratio := 0.35
var activation_height_ratio := 0.50
var visual_radius := 69.0
var visual_center := Vector2.ZERO
var finger_index := -1
var direction := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger_index < 0 and _activation_rect().has_point(_to_local(event.position)):
			finger_index = event.index
			visual_center = _clamp_center(_to_local(event.position))
			visible = true
			_set_direction(event.position)
		elif not event.pressed and event.index == finger_index:
			release_touch()
	elif event is InputEventScreenDrag and event.index == finger_index:
		_set_direction(event.position)

func _set_direction(screen_position: Vector2) -> void:
	direction = ((_to_local(screen_position) - visual_center) / visual_radius).limit_length()
	if direction.length() < DEAD_ZONE:
		direction = Vector2.ZERO
	Input.action_release("move_left")
	Input.action_release("move_right")
	if direction.x < 0.0:
		Input.action_press("move_left", -direction.x)
	elif direction.x > 0.0:
		Input.action_press("move_right", direction.x)
	queue_redraw()

func release_touch() -> void:
	finger_index = -1
	direction = Vector2.ZERO
	visible = false
	Input.action_release("move_left")
	Input.action_release("move_right")
	queue_redraw()

func _exit_tree() -> void:
	release_touch()

func _to_local(screen_position: Vector2) -> Vector2:
	return screen_position - global_position

func _activation_rect() -> Rect2:
	var zone_size := Vector2(size.x * activation_width_ratio, size.y * activation_height_ratio)
	return Rect2(Vector2(0.0, size.y - zone_size.y), zone_size)

func _clamp_center(point: Vector2) -> Vector2:
	var zone := _activation_rect()
	return Vector2(
		clampf(point.x, zone.position.x + visual_radius, zone.end.x - visual_radius),
		clampf(point.y, zone.position.y + visual_radius, zone.end.y - visual_radius)
	)

func _draw() -> void:
	var center := visual_center
	var radius := visual_radius
	draw_circle(center, radius, BASE_COLOR)
	draw_arc(center, radius, 0.0, TAU, 48, RIM_COLOR, 3.0, true)
	draw_arc(center, radius * 0.68, 0.0, TAU, 40, Color(0.69, 0.77, 0.70, 0.29), 1.5, true)
	var knob_center := center + direction * radius * 0.67
	draw_circle(knob_center, radius * 0.42, Color(0.04, 0.09, 0.12, 0.73))
	draw_circle(knob_center, radius * 0.36, KNOB_COLOR)
	draw_arc(knob_center, radius * 0.36, 0.0, TAU, 32, RIM_COLOR, 2.0, true)
