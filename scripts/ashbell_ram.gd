extends StaticBody2D

signal attacked(kind: String, damage: int, reach: float)
signal armor_shattered
signal part_broken(part_id: String)
signal wound_opened(part_id: String)
signal defeated

const BodyParts = preload("res://scripts/body_parts.gd")
const AGGRO_RANGE := 720.0

var max_health := 460
var health := 460
var phase := 1
var armor_meter := 0
var armor_broken := false
var body_parts = BodyParts.new({"horn": {"durability": 90, "wound_at": 50}, "chamber": {"durability": 110, "wound_at": 55}})
var selected_part := ""
var state := "idle"
var state_time := 1.25
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
	box.size = Vector2(190, 98)
	body.shape = box
	body.position = Vector2(0, -49)
	add_child(body)
	sprite = Sprite2D.new()
	sprite.texture = load("res://art/ashbell_ram.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * (138.0 / sprite.texture.get_height())
	sprite.position = Vector2(0, -69)
	add_child(sprite)

func attack_ids() -> Array[String]:
	return ["charge", "horn_swing", "toll_blast", "hoof_quake", "rebound"]

func part_ids() -> Array[String]:
	return ["horn", "chamber"]

func part_status(part_id: String) -> Dictionary:
	return body_parts.status(part_id)

func part_world_position(part_id: String) -> Vector2:
	if part_id == "horn":
		return global_position + Vector2(facing * 82, -92)
	if part_id == "chamber":
		return global_position + Vector2(facing * 8, -61)
	return global_position

func apply_status(status_id: String, duration: float) -> bool:
	if state == "dead" or status_id != "snare":
		return false
	state = "recover"
	state_time = maxf(state_time, duration)
	return true

func can_rebound() -> bool:
	return not bool(part_status("horn").get("broken", false))

func attack_profile(kind: String) -> Dictionary:
	var horn_broken: bool = bool(part_status("horn").get("broken", false))
	match kind:
		"charge":
			return {"damage": 29, "reach": 108.0 if horn_broken else 148.0, "speed": (285.0 if phase == 1 else 360.0) if horn_broken else (375.0 if phase == 1 else 470.0)}
		"horn_swing":
			return {"damage": 18 if horn_broken else 25, "reach": 92.0 if horn_broken else 142.0, "speed": 0.0}
		"toll_blast":
			return {"damage": 0 if armor_broken else 31, "reach": 0.0 if armor_broken else 218.0, "speed": 0.0}
		"hoof_quake":
			return {"damage": 21, "reach": 136.0, "speed": 0.0}
		"rebound":
			return {"damage": 27, "reach": 126.0, "speed": 520.0 if phase == 2 else 430.0}
	return {"damage": 1, "reach": 1.0, "speed": 0.0}

func next_attack_for_distance(distance: float) -> String:
	if distance > 270.0:
		return "charge"
	var choice := "horn_swing"
	match attack_count % 4:
		0: choice = "horn_swing"
		1: choice = "hoof_quake"
		2: choice = "toll_blast"
		_: choice = "charge"
	if choice == "toll_blast" and armor_broken:
		return "hoof_quake"
	return choice

func receive_hit(amount: int, kind: String, part_id: String = "chamber") -> void:
	if state == "dead":
		return
	var part_hit: Dictionary = body_parts.apply_hit(part_id, amount, kind)
	health = maxi(0, health - maxi(0, amount + int(part_hit["bonus_damage"])))
	hit_flash = 0.14
	if part_id == "chamber":
		armor_meter = int(part_status("chamber")["progress"])
	if part_hit["wound_opened"]:
		wound_opened.emit(part_id)
	if part_hit["broke"]:
		if part_id == "chamber":
			armor_broken = true
			armor_shattered.emit()
		part_broken.emit(part_id)
		if body_parts.broken_count() >= 2 and health > 0:
			state = "knockdown"
			state_time = 1.8
	if part_hit["stagger"] and health > 0 and state != "knockdown":
		state = "recover"
		state_time = maxf(state_time, 1.0)
	if health <= max_health / 2:
		phase = 2
	if health == 0:
		state = "dead"
		defeated.emit()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if state == "dead":
		if sprite != null:
			sprite.rotation = lerpf(sprite.rotation, 0.13 * facing, delta * 2.0)
		return
	if target == null or not is_instance_valid(target) or absf(target.global_position.x - global_position.x) > AGGRO_RANGE:
		return
	hit_flash = maxf(0.0, hit_flash - delta)
	walk_time += delta
	if state == "idle":
		var gap := target.global_position.x - global_position.x
		facing = -1 if gap < 0.0 else 1
		if absf(gap) > 205.0:
			position.x += signf(gap) * (58.0 if phase == 1 else 82.0) * delta
	elif state == "strike" and attack_kind in ["charge", "rebound"]:
		position.x += facing * float(attack_profile(attack_kind)["speed"]) * delta
	state_time -= delta
	if state_time <= 0.0:
		advance_state()
	if state == "strike":
		var profile := attack_profile(attack_kind)
		if int(profile["damage"]) > 0:
			attacked.emit(attack_kind, int(profile["damage"]) + (4 if phase == 2 else 0), float(profile["reach"]))
	if sprite != null:
		sprite.flip_h = facing > 0
		var lowered := 18.0 if state == "knockdown" else (8.0 if state == "exhausted" else 0.0)
		sprite.position.y = -69.0 + lowered + sin(walk_time * 5.0) * (2.2 if state == "idle" else 0.8)
		sprite.modulate = Color("#ffe0b1") if hit_flash > 0.0 else (Color("#aeb6b8") if armor_broken else Color.WHITE)
	queue_redraw()

func advance_state() -> void:
	match state:
		"idle":
			attack_kind = next_attack_for_distance(absf(target.global_position.x - global_position.x) if target != null and is_instance_valid(target) else 0.0)
			state = "windup"
			state_time = _windup_time(attack_kind)
		"windup":
			state = "strike"
			state_time = _strike_time(attack_kind)
		"strike":
			if attack_kind == "charge" and phase == 2 and can_rebound() and (attack_count + 1) % 3 == 0:
				attack_kind = "rebound"
				facing *= -1
				state = "combo_wait"
				state_time = 0.34
			else:
				_finish_attack()
		"combo_wait":
			state = "strike"
			state_time = _strike_time("rebound")
		"recover":
			state = "idle"
			state_time = 0.72 if phase == 1 else 0.43
		"exhausted":
			state = "idle"
			state_time = 0.55
		"knockdown":
			state = "idle"
			state_time = 0.60

func _finish_attack() -> void:
	attack_count += 1
	if attack_count % 5 == 0:
		state = "exhausted"
		state_time = 1.65
	else:
		state = "recover"
		state_time = 0.92 if phase == 1 else 0.58

func _windup_time(kind: String) -> float:
	match kind:
		"charge": return 0.94 if phase == 1 else 0.66
		"rebound": return 0.34
		"toll_blast": return 1.05 if phase == 1 else 0.78
		"hoof_quake": return 0.82 if phase == 1 else 0.60
		_: return 0.70 if phase == 1 else 0.50

func _strike_time(kind: String) -> float:
	return 0.34 if kind in ["charge", "rebound"] else 0.28

func _draw() -> void:
	if selected_part in part_ids():
		var spot := part_world_position(selected_part) - global_position
		var marked: Dictionary = part_status(selected_part)
		var color := Color("#dc7854") if marked["wounded"] else (Color("#8a9395") if marked["broken"] else Color("#e7bd70"))
		draw_arc(spot, 18.0, 0.0, TAU, 26, color, 2.5)
		draw_line(spot + Vector2(-5, 0), spot + Vector2(5, 0), color, 1.5)
	if state not in ["windup", "strike", "combo_wait"]:
		return
	var alpha := 0.36 if state != "strike" else 0.60
	var glow := Color(0.93, 0.66, 0.25, alpha)
	if attack_kind in ["charge", "rebound"]:
		draw_rect(Rect2(Vector2(95 if facing > 0 else -425, -14), Vector2(330, 12)), glow)
	elif attack_kind == "horn_swing":
		draw_arc(Vector2(facing * 45, -62), 152.0, -1.2 if facing > 0 else PI - 1.2, 1.2 if facing > 0 else PI + 1.2, 34, glow, 11.0)
	elif attack_kind == "toll_blast":
		draw_arc(Vector2(0, -62), 224.0, 0.0, TAU, 56, glow, 7.0)
	else:
		draw_arc(Vector2(0, -10), 146.0, 0.0, PI, 34, glow, 9.0)
