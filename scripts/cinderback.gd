extends StaticBody2D

signal attacked(kind: String, damage: int, reach: float)
signal armor_shattered
signal part_broken(part_id: String)
signal wound_opened(part_id: String)
signal defeated

const BodyParts = preload("res://scripts/body_parts.gd")
const AGGRO_RANGE := 650.0

var max_health := 320
var health := 320
var phase := 1
var armor_meter := 0
var armor_broken := false
var body_parts = BodyParts.new({"vent": {"durability": 50, "wound_at": 45}, "tail": {"durability": 80, "wound_at": 45}})
var selected_part := ""
var state := "idle"
var state_time := 1.3
var attack_kind := "rush"
var attack_count := 0
var facing := -1
var target: Node2D
var sprite: Sprite2D
var hit_flash := 0.0
var walk_time := 0.0

func _ready() -> void:
	var body := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(148, 78)
	body.shape = box
	body.position = Vector2(0, -39)
	add_child(body)
	sprite = Sprite2D.new()
	sprite.texture = load("res://art/cinderback.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * (115.0 / sprite.texture.get_height())
	sprite.position = Vector2(0, -57.5)
	add_child(sprite)

func part_ids() -> Array[String]:
	return ["vent", "tail"]

func attack_ids() -> Array[String]:
	var moves: Array[String] = ["rush"]
	if not bool(part_status("tail").get("broken", false)):
		moves.append("sweep")
	if not armor_broken:
		moves.append("burst")
	return moves

func part_status(part_id: String) -> Dictionary:
	return body_parts.status(part_id)

func part_world_position(part_id: String) -> Vector2:
	if part_id == "vent":
		return global_position + Vector2(0, -81)
	if part_id == "tail":
		return global_position + Vector2(-facing * 73, -35)
	return global_position

func apply_status(status_id: String, duration: float) -> bool:
	if state == "dead" or status_id != "snare":
		return false
	state = "recover"
	state_time = maxf(state_time, duration)
	return true

func attack_profile(kind: String) -> Dictionary:
	match kind:
		"burst": return {"damage": 19 if armor_broken else 26, "reach": 122.0 if armor_broken else 155.0, "speed": 0.0}
		"sweep": return {"damage": 12 if part_status("tail")["broken"] else 17, "reach": 78.0 if part_status("tail")["broken"] else 112.0, "speed": 0.0}
		_: return {"damage": 24, "reach": 112.0, "speed": 280.0 if phase == 1 else 370.0}

func receive_hit(amount: int, kind: String, part_id: String = "vent") -> void:
	if state == "dead":
		return
	var part_hit: Dictionary = body_parts.apply_hit(part_id, amount, kind)
	health = maxi(0, health - maxi(0, amount + int(part_hit["bonus_damage"])))
	hit_flash = 0.14
	if part_id == "vent":
		armor_meter = int(part_status("vent")["progress"])
	if part_hit["wound_opened"]:
		wound_opened.emit(part_id)
	if part_hit["broke"]:
		if part_id == "vent":
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
			sprite.rotation = lerpf(sprite.rotation, -0.12 * facing, delta * 2.0)
		return
	if target == null or not is_instance_valid(target) or absf(target.global_position.x - global_position.x) > AGGRO_RANGE:
		return
	hit_flash = maxf(0.0, hit_flash - delta)
	walk_time += delta
	if target != null and is_instance_valid(target):
		facing = -1 if target.global_position.x < global_position.x else 1
		if state == "idle":
			var gap := target.global_position.x - global_position.x
			if absf(gap) > 170.0:
				position.x += signf(gap) * (45.0 if phase == 1 else 68.0) * delta
		elif state == "strike" and attack_kind == "rush":
			position.x += facing * float(attack_profile("rush")["speed"]) * delta
	state_time -= delta
	if state_time <= 0.0:
		advance_state()
	if state == "strike":
		var profile := attack_profile(attack_kind)
		attacked.emit(attack_kind, int(profile["damage"]) + (6 if phase == 2 else 0), float(profile["reach"]))
	if sprite != null:
		sprite.flip_h = facing < 0
		var lowered := 6.0 if state == "exhausted" else 0.0
		sprite.position.y = -57.5 + lowered + sin(walk_time * 5.0) * (2.0 if state == "idle" else 1.0)
		sprite.modulate = Color("#ffc7a2") if hit_flash > 0.0 else (Color("#b9c7c7") if armor_broken else Color.WHITE)
	queue_redraw()

func advance_state() -> void:
	match state:
		"idle":
			attack_kind = _next_attack()
			state = "windup"
			state_time = 0.78 if phase == 1 else 0.52
		"windup":
			state = "strike"
			state_time = 0.32 if attack_kind == "rush" else 0.28
		"strike":
			_finish_attack()
		"recover":
			state = "idle"
			state_time = 0.7 if phase == 1 else 0.38
		"exhausted":
			state = "idle"
			state_time = 0.62

func _next_attack() -> String:
	if target != null and absf(target.global_position.x - global_position.x) > 240.0:
		return "rush"
	var moves := attack_ids()
	return moves[attack_count % moves.size()]

func _finish_attack() -> void:
	attack_count += 1
	if attack_count % 4 == 0:
		state = "exhausted"
		state_time = 1.3
	else:
		state = "recover"
		state_time = 0.82 if phase == 1 else 0.54

func _draw() -> void:
	if selected_part in part_ids():
		var spot := part_world_position(selected_part) - global_position
		var marked: Dictionary = part_status(selected_part)
		var color := Color("#dc7854") if marked["wounded"] else (Color("#8a9395") if marked["broken"] else Color("#e7bd70"))
		draw_arc(spot, 17.0, 0.0, TAU, 26, color, 2.5)
		draw_line(spot + Vector2(-5, 0), spot + Vector2(5, 0), color, 1.5)
	if state != "windup" and state != "strike":
		return
	var glow := Color(1.0, 0.32, 0.17, 0.34 if state == "windup" else 0.53)
	if attack_kind == "rush":
		draw_rect(Rect2(Vector2(85 * facing if facing > 0 else -365, -13), Vector2(280, 10)), glow)
	elif attack_kind == "sweep":
		draw_arc(Vector2(0, -34), 160, 0.1, PI - 0.1, 32, glow, 12.0)
	else:
		draw_arc(Vector2(0, -57), 174, 0, TAU, 50, glow, 5.0)
