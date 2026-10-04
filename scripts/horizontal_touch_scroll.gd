extends ScrollContainer

var touch_index := -1
var last_touch_x := 0.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index < 0:
			touch_index = event.index
			last_touch_x = event.position.x
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
	elif event is InputEventScreenDrag and event.index == touch_index:
		var movement: float = event.position.x - last_touch_x
		scroll_horizontal -= roundi(movement)
		last_touch_x = event.position.x
		accept_event()
