extends Node2D

const Cycle = preload("res://attack_cycle.gd")
const WORDS := {"ready": "SẴN SÀNG", "raise": "NÂNG KIẾM", "hold": "TÍCH LỰC",
	"strike": "BỔ XUỐNG", "settle": "THEO ĐÀ", "recover": "HỒI THẾ"}
var cycle = Cycle.new()
var manifest: Dictionary
var body: Texture2D
var weapon: Texture2D
var font: Font
var touch_id := -1
var stick_origin := Vector2.ZERO
var stick_tip := Vector2.ZERO
var target_flash := 0.0
var hit_seen := 0
var damage_total := 0
var last_damage := 0
var automatic := false
var auto_wait := 0.0
var auto_charge := false
var large := false
var elapsed := 0.0

func _ready() -> void:
	body = load("res://assets/body.png")
	weapon = load("res://assets/weapon.png")
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/frames.json"))
	font = ThemeDB.fallback_font
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	set_process(true)

func attack_zone(point: Vector2) -> bool:
	var size := get_viewport_rect().size
	return point.x > size.x * .60 and point.y > size.y * .43

func buttons() -> Array[Rect2]:
	var width := get_viewport_rect().size.x
	return [Rect2(width - 410, 22, 125, 42), Rect2(width - 275, 22, 120, 42),
		Rect2(width - 145, 22, 120, 42)]

func press_at(point: Vector2, id: int) -> void:
	var controls := buttons()
	for i in controls.size():
		if controls[i].has_point(point):
			match i:
				0:
					automatic = not automatic
					auto_wait = 0.0
					if not automatic: cycle.release()
				1: large = not large
				2:
					cycle.reset()
					hit_seen = 0
					damage_total = 0
					last_damage = 0
					target_flash = 0.0
					touch_id = -1
			return
	if touch_id == -1 and attack_zone(point) and cycle.press():
		automatic = false
		touch_id = id
		stick_origin = point
		stick_tip = point

func release_at(id: int) -> void:
	if id == touch_id:
		touch_id = -1
		cycle.release()

func _input(event: InputEvent) -> void:
	# Android may synthesize a mouse click for the same touch. Consume only the
	# native touch, otherwise toggle buttons execute twice.
	if event is InputEventMouse and event.device == -1:
		return
	if event is InputEventScreenTouch:
		if event.pressed: press_at(event.position, event.index)
		else: release_at(event.index)
	elif event is InputEventScreenDrag and event.index == touch_id:
		stick_tip = stick_origin + (event.position - stick_origin).limit_length(48)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: press_at(event.position, -2)
		else: release_at(-2)
	elif event is InputEventMouseMotion and touch_id == -2:
		stick_tip = stick_origin + (event.position - stick_origin).limit_length(48)
	elif event is InputEventKey and event.keycode == KEY_SPACE and not event.echo:
		if event.pressed:
			automatic = false
			cycle.press()
		else: cycle.release()
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and cycle != null:
		touch_id = -1
		cycle.release()

func _process(delta: float) -> void:
	elapsed += delta
	if automatic:
		if cycle.state == "ready":
			auto_wait += delta
			if auto_wait > .5:
				cycle.press()
				auto_charge = not auto_charge
				auto_wait = 0.0
		elif (not auto_charge and cycle.state == "raise") or (
			auto_charge and cycle.charge_time >= 1.5):
			cycle.release()
	cycle.step(delta)
	apply_impact()
	target_flash = maxf(0, target_flash - delta)
	queue_redraw()

func apply_impact() -> void:
	if cycle.hit_count > hit_seen:
		hit_seen = cycle.hit_count
		last_damage = cycle.impact_damage
		damage_total += last_damage
		target_flash = .4
		print("OVERHEAD_IMPACT damage=%d hits=%d" % [last_damage, hit_seen])

func current_frame() -> int:
	var numbers: Array = manifest.stages[cycle.state]
	if cycle.state == "ready": return int(numbers[0])
	var progress: float
	if cycle.state == "hold": progress = fmod(cycle.elapsed, .4) / .4
	else: progress = clampf(cycle.elapsed / float(Cycle.LENGTHS[cycle.state]), 0, .99999)
	return int(numbers[mini(numbers.size() - 1, int(progress * numbers.size()))])

func text(at: Vector2, words: String, size: int, colour := Color("eaf0e3")) -> void:
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)

func _draw() -> void:
	if manifest.is_empty(): return
	var screen := get_viewport_rect().size
	var floor_y := floorf(screen.y * .72)
	var art_scale := 1.6 if large else 1.0
	var actor := Vector2(floorf(screen.x * .41), floor_y)
	var dummy := actor + Vector2(98 * art_scale, 0)
	draw_rect(Rect2(Vector2.ZERO, screen), Color("8da9af"))
	# Bright training court, with muted silhouettes behind the red/steel hunter.
	for i in 9:
		var x := i * screen.x / 7.0 - 80
		draw_colored_polygon(PackedVector2Array([Vector2(x - 130, floor_y),
			Vector2(x + 15, screen.y * .22 + sin(i * 2.1) * 40),
			Vector2(x + 160, floor_y)]), Color("78969b"))
	draw_rect(Rect2(0, floor_y, screen.x, screen.y - floor_y), Color("465860"))
	draw_rect(Rect2(0, floor_y, screen.x, 7), Color("c4c4a0"))
	for i in int(screen.x / 64) + 1:
		draw_line(Vector2(i * 64, floor_y + 9), Vector2(i * 64 - 12, screen.y), Color("3b4c54"), 2)
	# Practice target: post, wrapped straw chest and a padded head.
	var flash := Color("fff3c2") if target_flash > 0 else Color("bd9060")
	draw_rect(Rect2(dummy + Vector2(-5, -72) * art_scale, Vector2(10, 72) * art_scale), Color("6e4b3e"))
	draw_rect(Rect2(dummy + Vector2(-20, -61) * art_scale, Vector2(40, 32) * art_scale), flash)
	for y in [-56, -45, -34]:
		draw_line(dummy + Vector2(-20, y) * art_scale, dummy + Vector2(20, y) * art_scale, Color("805641"), 3 * art_scale)
	draw_circle(dummy + Vector2(0, -75) * art_scale, 11 * art_scale, flash)
	var frame: Dictionary = manifest.frames[current_frame()]
	draw_texture_rect_region(body, Rect2(actor - Vector2(64, 116) * art_scale,
		Vector2(128, 128) * art_scale), Rect2(frame.body[0], frame.body[1], 128, 128))
	draw_texture_rect_region(weapon, Rect2(actor - Vector2(192, 244) * art_scale,
		Vector2(384, 384) * art_scale), Rect2(frame.weapon[0], frame.weapon[1], 384, 384))
	if target_flash > 0:
		text(dummy + Vector2(-22, -108) * art_scale, str(last_damage), 26, Color("fff0a7"))
	text(Vector2(30, 44), "MIST & IRON  /  ĐẠI KIẾM", 24, Color("203442"))
	text(Vector2(30, 76), "Tập đòn bổ xuống", 18, Color("314c58"))
	text(Vector2(30, 112), str(WORDS[cycle.state]), 20, Color("273e4a"))
	text(Vector2(30, 142), "Trúng: %d    Tổng sát thương: %d" % [hit_seen, damage_total], 17, Color("314c58"))
	var controls := buttons()
	var names := ["Tự diễn: " + ("BẬT" if automatic else "TẮT"),
		"Thu nhỏ" if large else "Phóng to", "Làm lại"]
	for i in controls.size():
		draw_style_box(button_style(), controls[i])
		text(controls[i].position + Vector2(12, 28), names[i], 16)
	var hint := Vector2(screen.x * .70, screen.y * .83)
	if touch_id != -1:
		draw_circle(stick_origin, 62, Color(0.12, 0.22, 0.28, .5))
		draw_arc(stick_origin, 62, 0, TAU, 48, Color("e4ce94"), 3)
		draw_circle(stick_tip, 23, Color("c7b485"))
	else:
		text(hint, "CHẠM / GIỮ → NHẢ", 20)
	text(Vector2(30, screen.y - 40), "Chạm nhanh: bổ thường  •  Giữ: tích lực  •  Nhả: bổ xuống", 18)
	text(Vector2(30, screen.y - 16), "Máy tính: giữ phím Space hoặc chuột ở vùng bên phải", 14, Color("aebfc1"))
	if cycle.state == "hold" or cycle.state == "raise":
		var bar := Rect2(actor.x - 45, actor.y - 143 * art_scale, 90, 6)
		draw_rect(bar, Color("324956"))
		draw_rect(Rect2(bar.position, Vector2(90 * minf(1, cycle.charge_time / 2.4), 6)), Color("f4d48a"))

func button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("314a58")
	style.set_corner_radius_all(8)
	return style
