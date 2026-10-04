extends CharacterBody2D

signal struck(damage: int, reach: float, kind: String)
signal wounded
signal died
signal healed

const Rules = preload("res://scripts/rules.gd")
const WALK_SPEED := 225.0
const JUMP_SPEED := -700.0
const GRAVITY := 1900.0
const ART_HEIGHT := 90.0
const SHEATH_DELAY := 3.5

var max_health := 100
var health := 100
var stamina := 100.0
var max_stamina := 100.0
var forge_level := 0
var weapon_type := "blade"
var armor_type := "field"
var facing := 1
var invincible_time := 0.0
var dodge_time := 0.0
var attack_time := 0.0
var attack_cooldown := 0.0
var attack_fired := false
var attack_kind := ""
var attack_charge := 0.0
var attack_emit_at := 0.0
var charge_time := 0.0
var hurt_time := 0.0
var moving_time := 0.0
var has_control := true
var potions := 2
var heal_time := 0.0
var sprite: Sprite2D

var current_action := ""
var action_elapsed := 0.0
var buffered_token := ""
var weapon_resource := 0.0
var weapon_drawn := false
var idle_combat_time := 0.0
var guard_time := 0.0
var counter_time := 0.0
var hit_stop_time := 0.0
var hit_confirmed := false

func _ready() -> void:
	max_health = Rules.coat_max_health(armor_type)
	health = max_health
	max_stamina = Rules.coat_max_stamina(armor_type)
	stamina = max_stamina
	var shape := CollisionShape2D.new()
	var body := RectangleShape2D.new()
	body.size = Vector2(28, 72)
	shape.shape = body
	shape.position = Vector2(0, -36)
	add_child(shape)
	sprite = Sprite2D.new()
	var weapon_data := Rules.weapon(weapon_type)
	sprite.texture = load(str(weapon_data["art"]))
	sprite.modulate = weapon_data.get("tint", Color.WHITE)
	var pixel_scale := ART_HEIGHT / float(sprite.texture.get_height())
	sprite.scale = Vector2(pixel_scale, pixel_scale)
	sprite.position = Vector2(0, -ART_HEIGHT / 2.0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	weapon_resource = float(weapon_data.get("resource_start", 0.0))

func _physics_process(delta: float) -> void:
	advance_heal(delta)
	invincible_time = maxf(0.0, invincible_time - delta)
	dodge_time = maxf(0.0, dodge_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	guard_time = maxf(0.0, guard_time - delta)
	counter_time = maxf(0.0, counter_time - delta)
	if hit_stop_time > 0.0:
		hit_stop_time = maxf(0.0, hit_stop_time - delta)
		_update_art(0.0)
		return
	stamina = minf(max_stamina, stamina + delta * (9.0 if charge_time > 0.0 else 19.0))
	if current_action == "guard_set":
		stamina = maxf(0.0, stamina - delta * 8.0)
		if stamina <= 0.0:
			guard_time = 0.0
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var axis := Input.get_axis("move_left", "move_right")
	if has_control and health > 0:
		if Input.is_action_just_pressed("heal"):
			start_heal()
		if Input.is_action_just_pressed("dodge") and heal_time <= 0.0:
			start_dodge()
		if Input.is_action_just_pressed("special") and heal_time <= 0.0:
			request_action("special", absf(axis) > 0.45, not is_on_floor())
		if Input.is_action_just_pressed("attack") and heal_time <= 0.0:
			request_action("light", absf(axis) > 0.45, not is_on_floor())
		if weapon_type == "blade":
			if Input.is_action_pressed("heavy") and current_action.is_empty() and heal_time <= 0.0:
				charge_time = minf(1.15, charge_time + delta)
			elif charge_time > 0.0:
				start_action("charged_hew", charge_time / 1.15)
				charge_time = 0.0
		elif Input.is_action_just_pressed("heavy") and heal_time <= 0.0:
			request_action("heavy", absf(axis) > 0.45, not is_on_floor())
		if Input.is_action_just_pressed("jump") and is_on_floor() and dodge_time <= 0.0 and heal_time <= 0.0 and current_action.is_empty():
			velocity.y = JUMP_SPEED
		if axis != 0.0:
			facing = -1 if axis < 0.0 else 1
		if heal_time > 0.0:
			velocity.x = axis * 65.0
		elif dodge_time > 0.0:
			velocity.x = facing * 410.0
		elif not current_action.is_empty():
			velocity.x = move_toward(velocity.x, 0.0, 850.0 * delta)
		else:
			var walk_scale := float(Rules.weapon(weapon_type).get("walk_multiplier", 1.0)) if weapon_drawn else 1.0
			velocity.x = axis * WALK_SPEED * walk_scale
	else:
		velocity.x = move_toward(velocity.x, 0.0, 750.0 * delta)
	advance_action(delta)
	if current_action.is_empty() and dodge_time <= 0.0:
		idle_combat_time += delta
		if idle_combat_time >= SHEATH_DELAY:
			weapon_drawn = false
	else:
		idle_combat_time = 0.0
	move_and_slide()
	if global_position.y > 650.0:
		take_hit(999)
	_update_art(delta)

func request_action(token: String, directional: bool = false, airborne: bool = false) -> bool:
	var requested := "directional" if token == "light" and directional else token
	if not current_action.is_empty():
		var data := Rules.action(current_action, weapon_type)
		if action_elapsed < float(data.get("combo_open", 0.0)):
			return false
		var followup := Rules.followup_action(current_action, requested, weapon_type)
		if followup.is_empty() and requested == "directional":
			followup = Rules.followup_action(current_action, "light", weapon_type)
		if followup.is_empty():
			return false
		buffered_token = followup
		return true
	var weapon_data := Rules.weapon(weapon_type)
	var action_id := ""
	match token:
		"special": action_id = str(weapon_data["special"])
		"heavy": action_id = str(weapon_data["heavy"])
		"light":
			if airborne:
				action_id = str(weapon_data["aerial"])
			elif dodge_time > 0.0:
				action_id = str(weapon_data["dodge"])
				dodge_time = 0.0
			elif directional:
				action_id = str(weapon_data["directional"])
			elif not weapon_drawn:
				action_id = str(weapon_data["entry"])
			else:
				action_id = str(weapon_data["light"])
	if action_id.is_empty():
		return false
	return start_action(action_id)

func start_action(action_id: String, charge: float = 0.0) -> bool:
	return _begin_action(action_id, charge, true)

func _begin_action(action_id: String, charge: float, spend_costs: bool) -> bool:
	var data := Rules.action(action_id, weapon_type)
	if data.is_empty() or not current_action.is_empty() or dodge_time > 0.0 or heal_time > 0.0 or health <= 0:
		return false
	var stamina_cost := float(data.get("stamina", 0.0)) if spend_costs else 0.0
	var resource_cost := float(data.get("resource_cost", 0.0)) if spend_costs else 0.0
	if not Rules.can_spend_stamina(stamina, stamina_cost) or weapon_resource < resource_cost:
		return false
	stamina -= stamina_cost
	weapon_resource -= resource_cost
	current_action = action_id
	attack_kind = action_id
	attack_charge = clampf(charge, 0.0, 1.0)
	action_elapsed = 0.0
	attack_time = float(data["duration"])
	attack_emit_at = float(data["hit_at"])
	attack_cooldown = 0.0
	attack_fired = false
	hit_confirmed = false
	buffered_token = ""
	weapon_drawn = true
	idle_combat_time = 0.0
	velocity.x = facing * float(data.get("move", 0.0))
	if action_id == "counter_guard":
		counter_time = attack_time
	if action_id == "guard_set" or action_id == "shoulder_brace":
		guard_time = attack_time
	queue_redraw()
	return true

func advance_action(delta: float) -> void:
	if current_action.is_empty() or delta <= 0.0:
		return
	var data := Rules.action(current_action, weapon_type)
	action_elapsed += delta
	attack_time = maxf(0.0, float(data["duration"]) - action_elapsed)
	if not attack_fired and action_elapsed >= float(data["hit_at"]):
		attack_fired = true
		if int(data["damage"]) > 0:
			struck.emit(current_damage(), float(data["reach"]), current_action)
	if action_elapsed < float(data["duration"]):
		return
	var next_action := buffered_token
	current_action = ""
	attack_kind = ""
	attack_time = 0.0
	action_elapsed = 0.0
	buffered_token = ""
	guard_time = 0.0
	counter_time = 0.0
	if not next_action.is_empty():
		_begin_action(next_action, 0.0, true)
	else:
		attack_cooldown = 0.04

func confirm_hit(action_id: String) -> bool:
	if hit_confirmed or current_action != action_id:
		return false
	var data := Rules.action(action_id, weapon_type)
	if data.is_empty():
		return false
	hit_confirmed = true
	var gain := float(data.get("resource_gain", 0.0))
	if weapon_type == "blade" and action_id == "charged_hew" and attack_charge >= 0.85:
		gain = 1.0
	weapon_resource = minf(resource_max(), weapon_resource + gain)
	hit_stop_time = maxf(hit_stop_time, float(data.get("hit_stop", 0.0)))
	return true

func current_damage() -> int:
	if current_action.is_empty():
		return 0
	return Rules.action_damage(current_action, attack_charge, forge_level, weapon_type)

func resource_name() -> String:
	return str(Rules.weapon(weapon_type).get("resource_name", ""))

func resource_max() -> float:
	return float(Rules.weapon(weapon_type).get("resource_max", 0.0))

func start_dodge() -> bool:
	var dodge_cost := Rules.coat_dodge_cost(armor_type)
	if not Rules.can_spend_stamina(stamina, dodge_cost) or dodge_time > 0.0 or heal_time > 0.0 or health <= 0 or not current_action.is_empty():
		return false
	stamina -= dodge_cost
	dodge_time = 0.26
	invincible_time = maxf(invincible_time, 0.34)
	return true

func start_attack(kind: String, charge: float) -> bool:
	var action_id := Rules.entry_action(weapon_type) if kind == "quick" else str(Rules.weapon(weapon_type)["heavy"])
	return start_action(action_id, charge)

func start_heal() -> bool:
	if health <= 0 or health >= max_health or potions <= 0 or heal_time > 0.0 or not current_action.is_empty() or dodge_time > 0.0:
		return false
	charge_time = 0.0
	heal_time = 0.8
	return true

func advance_heal(delta: float) -> void:
	if heal_time <= 0.0:
		return
	heal_time = maxf(0.0, heal_time - delta)
	if heal_time == 0.0 and health > 0:
		health = mini(max_health, health + 35)
		potions -= 1
		healed.emit()

func add_potion() -> bool:
	if potions >= 3:
		return false
	potions += 1
	return true

func take_hit(amount: int) -> void:
	if health <= 0 or invincible_time > 0.0:
		return
	if weapon_type == "counter" and counter_time > 0.0 and current_action == "counter_guard":
		weapon_resource = minf(resource_max(), weapon_resource + 10.0)
		_force_action("counter_riposte")
		invincible_time = 0.28
		return
	if weapon_type == "pike" and guard_time > 0.0 and current_action == "guard_set" and weapon_resource > 0.0:
		weapon_resource = maxf(0.0, weapon_resource - maxf(12.0, amount * 1.25))
		stamina = maxf(0.0, stamina - amount * 0.35)
		_apply_damage(maxi(1, roundi(amount * 0.25)), 0.25, false)
		if health > 0:
			_force_action("counter_thrust")
		return
	if weapon_type == "blade" and guard_time > 0.0 and current_action == "shoulder_brace":
		_apply_damage(maxi(1, roundi(amount * 0.5)), 0.30, false)
		return
	_apply_damage(amount, 0.75, true)

func _force_action(action_id: String) -> void:
	current_action = ""
	attack_kind = ""
	attack_time = 0.0
	buffered_token = ""
	guard_time = 0.0
	counter_time = 0.0
	_begin_action(action_id, 0.0, false)

func _apply_damage(amount: int, immunity: float, interrupt: bool) -> void:
	heal_time = 0.0
	health = maxi(0, health - Rules.coat_damage(amount, armor_type))
	invincible_time = immunity
	hurt_time = 0.22
	velocity.x = -facing * 165.0
	if interrupt:
		current_action = ""
		attack_kind = ""
		attack_time = 0.0
		buffered_token = ""
		guard_time = 0.0
		counter_time = 0.0
	wounded.emit()
	if health == 0:
		has_control = false
		died.emit()

func _update_art(delta: float) -> void:
	if sprite == null:
		return
	moving_time += delta
	var bob := 2.0 * sin(moving_time * 17.0) if absf(velocity.x) > 20.0 and is_on_floor() else 0.0
	var visual_x := 11.0 if weapon_type == "pike" else (4.0 if weapon_type == "maul" else 0.0)
	sprite.position = Vector2(visual_x * facing, -ART_HEIGHT / 2.0 + bob)
	sprite.rotation = -0.08 * facing if not current_action.is_empty() else 0.0
	sprite.flip_h = facing < 0
	var base_tint: Color = Rules.weapon(weapon_type).get("tint", Color.WHITE)
	sprite.modulate = Color(1.0, 0.55, 0.5) if hurt_time > 0.0 else (Color("#a8e7ad") if heal_time > 0.0 else base_tint)
	sprite.visible = not (invincible_time > 0.0 and fmod(invincible_time, 0.12) < 0.05)
	queue_redraw()

func _draw() -> void:
	if charge_time > 0.18:
		var width := 48.0 + 15.0 * minf(charge_time, 1.0)
		draw_arc(Vector2(0, -47), width, -1.5, 1.5, 14, Color("#e6b967"), 3.0)
	if not current_action.is_empty() and attack_fired:
		var start := Vector2(25 * facing, -67)
		var reach: float = float(Rules.action(current_action, weapon_type).get("reach", 90.0))
		var end := Vector2((reach + 8.0) * facing, -25)
		var trail := Color("#f3b862") if weapon_type == "maul" else (Color("#c6e7d9") if weapon_type == "pike" else (Color("#dda8ff") if weapon_type == "counter" else (Color("#ff9dad") if weapon_type == "twins" else Color("#f1dfa8"))))
		draw_line(start, end, trail, 7.0 if weapon_type == "maul" else 4.0)
		draw_line(start + Vector2(0, 6), end + Vector2(0, 6), Color("#b88a4c"), 3.0)
