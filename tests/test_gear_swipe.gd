extends SceneTree

const GameUI = preload("res://scripts/game_ui.gd")
const Store = preload("res://scripts/save_store.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ui = GameUI.new()
	root.add_child(ui)
	ui.show_gear(Store.defaults())
	await process_frame
	var scroll: ScrollContainer = ui.root.get_node("WeaponScroll")
	var cards: Control = scroll.get_node("WeaponCards")
	_check(cards.mouse_filter == Control.MOUSE_FILTER_PASS, "card surface passes touch drags to the horizontal scroller")
	_check(scroll.scroll_deadzone <= 8, "weapon swipe starts after a short deliberate drag")
	var start := Vector2(520, 100)
	_send_touch(scroll, 12, true, start)
	_send_drag(scroll, 12, start - Vector2(220, 0), Vector2(-220, 0))
	_send_touch(scroll, 12, false, start - Vector2(220, 0))
	_check(scroll.scroll_horizontal > 0, "dragging across the upper card area scrolls the weapon list")
	ui.queue_free()
	quit(1 if failures > 0 else 0)

func _send_touch(scroll: ScrollContainer, finger: int, pressed: bool, at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.pressed = pressed
	event.position = at
	scroll._gui_input(event)

func _send_drag(scroll: ScrollContainer, finger: int, at: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = finger
	event.position = at
	event.relative = relative
	scroll._gui_input(event)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
