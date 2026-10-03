extends Control

var action := "attack"
var caption := ""
var primary := false
var finger_index := -1
var caption_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_label = Label.new()
	caption_label.text = caption
	caption_label.size = size
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_label.add_theme_font_size_override("font_size", 16 if primary else 13)
	caption_label.add_theme_color_override("font_color", Color("#fff0c5"))
	caption_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	caption_label.add_theme_constant_override("shadow_offset_x", 1)
	caption_label.add_theme_constant_override("shadow_offset_y", 2)
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption_label)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger_index < 0 and _inside(event.position):
			finger_index = event.index
			Input.action_press(action)
			queue_redraw()
		elif not event.pressed and event.index == finger_index:
			release_touch()

func _inside(screen_position: Vector2) -> bool:
	var offset := screen_position - global_position - size / 2.0
	return offset.length() <= minf(size.x, size.y) * 0.5

func release_touch() -> void:
	finger_index = -1
	Input.action_release(action)
	queue_redraw()

func _exit_tree() -> void:
	release_touch()

func _draw() -> void:
	var center := size / 2.0
	var radius: float = minf(size.x, size.y) * 0.48
	var pressed := finger_index >= 0
	var fill := Color("#805038") if primary else Color("#354d54")
	if pressed:
		fill = Color("#bb8050") if primary else Color("#59716b")
	fill.a = 0.86
	draw_circle(center, radius, Color(0.02, 0.06, 0.09, 0.62))
	draw_circle(center, radius - 4.0, fill)
	draw_arc(center, radius - 1.0, 0.0, TAU, 40, Color("#e1b66e"), 3.0, true)
	draw_arc(center, radius * 0.71, 0.0, TAU, 40, Color(1.0, 0.88, 0.67, 0.25), 1.0, true)
