extends StaticBody2D

signal attacked(kind: String, damage: int, reach: float)
signal armor_shattered
signal part_broken(part_id: String)
signal wound_opened(part_id: String)
signal defeated

const BodyParts = preload("res://scripts/body_parts.gd")
const AGGRO_RANGE := 650.0

var max_health := 400
var health := 400
var phase := 1
var armor_meter := 0
var armor_broken := false
var body_parts = BodyParts.new({"antler": {"durability": 65, "wound_at": 45}, "hoof": {"durability": 80, "wound_at": 45}})
var selected_part := ""
var state := "idle"
var state_time := 1.2
var attack_kind := "charge"
var attack_count := 0
var facing := -1
var target: Node2D
var sprite: Sprite2D
var hit_flash := 0.0
var walk_time := 0.0

func _ready() -> void:
	var body := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(152, 90)
	body.shape = box
	body.position = Vector2(0, -45)
	add_child(body)
	sprite = Sprite2D.new()
	sprite.texture = load("res://art/thornhart.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * (135.0 / sprite.texture.get_height())
	sprite.position = Vector2(0, -67.5)
	add_child(sprite)

func part_ids() -> Array[String]:
	return ["antler", "hoof"]

func part_status(part_id: String) -> Dictionary:
	return body_parts.status(part_id)

func part_world_position(part_id: String) -> Vector2:
	if part_id == "antler":
		return global_position + Vector2(facing * 57, -105)
	if part_id == "hoof":
		return global_position + Vector2(-facing * 40, -22)
	return global_position

func apply_status(status_id: String, duration: float) -> bool:
	if state == "dead" or status_id != "snare":
		return false
	state = "recover"
	state_time = maxf(state_time, duration)
	return true

func attack_profile(kind: String) -> Dictionary:
	match kind:
		"charge": return {"damage": 24, "reach": 95.0 if part_status("hoof")["broken"] else 125.0, "speed": (240.0 if phase == 1 else 330.0) if part_status("hoof")["broken"] else (320.0 if phase == 1 else 440.0)}
		"stomp": return {"damage": 20, "reach": 112.0, "speed": 0.0}
		_: return {"damage": 17 if armor_broken else 28, "reach": 130.0 if armor_broken else 178.0, "speed": 0.0}

func receive_hit(amount: int, kind: String, part_id: String = "antler") -> void:
	if state == "dead":
		return
	var part_hit: Dictionary = body_parts.apply_hit(part_id, amount, kind)
	health = maxi(0, health - maxi(0, amount + int(part_hit["bonus_damage"])))
	hit_flash = 0.14
	if part_id == "antler":
		armor_meter = int(part_status("antler")["progress"])
	if part_hit["wound_opened"]:
		wound_opened.emit(part_id)
	if part_hit["broke"]:
		if part_id == "antler":
			armor_broken = true
			armor_shattered.emit()
		part_broken.emit(part_id)
	if part_hit["stagger"] and health > 0:
		state = "recover"
		state_time = maxf(state_time, 0.9)
	if health <= max_health / 2:
		phase = 2
	if health == 0:
		state = "dead"
		defeated.emit()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if state == "dead":
		if sprite != null:
			sprite.rotation = lerpf(sprite.rotation, 0.15 * facing, delta * 2.0)
		return
	if target == null or not is_instance_valid(target) or absf(target.global_position.x - global_position.x) > AGGRO_RANGE:
		return
	hit_flash = maxf(0.0, hit_flash - delta)
	walk_time += delta
	if target != null and is_instance_valid(target):
		facing = -1 if target.global_position.x < global_position.x else 1
		if state == "idle":
			var gap := target.global_position.x - global_position.x
			if absf(gap) > 185.0:
				position.x += signf(gap) * (68.0 if phase == 1 else 94.0) * delta
		elif state == "strike" and attack_kind == "charge":
			position.x += facing * float(attack_profile("charge")["speed"]) * delta
	state_time -= delta
	if state_time <= 0.0:
		advance_state()
	if state == "strike":
		var profile := attack_profile(attack_kind)
		attacked.emit(attack_kind, int(profile["damage"]) + (5 if phase == 2 else 0), float(profile["reach"]))
	if sprite != null:
		sprite.flip_h = facing > 0
		sprite.position.y = -67.5 + sin(walk_time * 5.5) * (2.5 if state == "idle" else 1.0)
		sprite.modulate = Color("#ffe3b2") if hit_flash > 0.0 else (Color("#b5ba9a") if armor_broken else Color.WHITE)
	queue_redraw()

func advance_state() -> void:
	match state:
		"idle":
			attack_kind = _next_attack()
			state = "windup"
			state_time = 0.88 if phase == 1 else 0.58
		"windup":
			state = "strike"
			state_time = 0.34 if attack_kind == "charge" else 0.28
		"strike":
			state = "recover"
			state_time = 0.85 if phase == 1 else 0.55
		"recover":
			state = "idle"
			state_time = 0.75 if phase == 1 else 0.44

func _next_attack() -> String:
	attack_count += 1
	if target != null and absf(target.global_position.x - global_position.x) > 270.0:
		return "charge"
	match attack_count % 3:
		0: return "thorns"
		1: return "stomp"
		_: return "charge"

func _draw() -> void:
	if selected_part in part_ids():
		var spot := part_world_position(selected_part) - global_position
		var marked: Dictionary = part_status(selected_part)
		var color := Color("#dc7854") if marked["wounded"] else (Color("#8a9395") if marked["broken"] else Color("#e7bd70"))
		draw_arc(spot, 17.0, 0.0, TAU, 26, color, 2.5)
		draw_line(spot + Vector2(-5, 0), spot + Vector2(5, 0), color, 1.5)
	if state != "windup" and state != "strike":
		return
	var glow := Color(0.54, 0.81, 0.31, 0.37 if state == "windup" else 0.61)
	if attack_kind == "charge":
		draw_rect(Rect2(Vector2(90 if facing > 0 else -380, -12), Vector2(290, 10)), glow)
	elif attack_kind == "stomp":
		draw_arc(Vector2(0, -10), 126, 0.0, PI, 30, glow, 8.0)
	else:
		draw_arc(Vector2(0, -60), 192, 0.0, TAU, 50, glow, 6.0)
