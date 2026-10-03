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

var max_health := 100
var health := 100
var stamina := 100.0
var forge_level := 0
var weapon_type := "blade"
var facing := 1
var invincible_time := 0.0
var dodge_time := 0.0
var attack_time := 0.0
var attack_cooldown := 0.0
var attack_fired := false
var attack_kind := "quick"
var attack_charge := 0.0
var attack_emit_at := 0.0
var charge_time := 0.0
var hurt_time := 0.0
var moving_time := 0.0
var has_control := true
var potions := 2
var heal_time := 0.0
var sprite: Sprite2D

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var body := RectangleShape2D.new()
	body.size = Vector2(28, 72)
	shape.shape = body
	shape.position = Vector2(0, -36)
	add_child(shape)
	sprite = Sprite2D.new()
	var art_path := "res://art/hunter.png"
	if weapon_type == "pike":
		art_path = "res://art/hunter_pike.png"
	elif weapon_type == "maul":
		art_path = "res://art/hunter_maul.png"
	sprite.texture = load(art_path)
	var pixel_scale := ART_HEIGHT / float(sprite.texture.get_height())
	sprite.scale = Vector2(pixel_scale, pixel_scale)
	sprite.position = Vector2(0, -ART_HEIGHT / 2.0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func _physics_process(delta: float) -> void:
	advance_heal(delta)
	invincible_time = maxf(0.0, invincible_time - delta)
	dodge_time = maxf(0.0, dodge_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	stamina = minf(100.0, stamina + delta * (9.0 if charge_time > 0.0 else 19.0))
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if has_control and health > 0:
		if Input.is_action_just_pressed("heal"):
			start_heal()
		if Input.is_action_just_pressed("dodge") and heal_time <= 0.0:
			start_dodge()
		if Input.is_action_just_pressed("attack") and heal_time <= 0.0:
			start_attack("quick", 0.0)
		if Input.is_action_pressed("heavy") and attack_time <= 0.0 and heal_time <= 0.0:
			charge_time = minf(1.15, charge_time + delta)
		elif charge_time > 0.0:
			start_attack("heavy", charge_time / 1.15)
			charge_time = 0.0
		if Input.is_action_just_pressed("jump") and is_on_floor() and dodge_time <= 0.0 and heal_time <= 0.0:
			velocity.y = JUMP_SPEED
		var axis := Input.get_axis("move_left", "move_right")
		if axis != 0.0:
			facing = -1 if axis < 0.0 else 1
		if heal_time > 0.0:
			velocity.x = axis * 65.0
		elif dodge_time > 0.0:
			velocity.x = facing * 410.0
		elif attack_time > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, 850.0 * delta)
		else:
			velocity.x = axis * WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, 750.0 * delta)
	if attack_time > 0.0:
		attack_time -= delta
		if not attack_fired and attack_time <= attack_emit_at:
			attack_fired = true
			struck.emit(Rules.attack_damage(attack_kind, attack_charge, forge_level, weapon_type), Rules.attack_reach(attack_kind, weapon_type), attack_kind)
	move_and_slide()
	if global_position.y > 650.0:
		take_hit(999)
	_update_art(delta)

func start_dodge() -> bool:
	if not Rules.can_spend_stamina(stamina, 22.0) or dodge_time > 0.0 or heal_time > 0.0 or health <= 0:
		return false
	stamina -= 22.0
	dodge_time = 0.26
	invincible_time = maxf(invincible_time, 0.34)
	attack_time = 0.0
	return true

func start_attack(kind: String, charge: float) -> bool:
	var cost: float = Rules.attack_cost(kind, weapon_type)
	if not Rules.can_spend_stamina(stamina, cost) or attack_cooldown > 0.0 or dodge_time > 0.0 or heal_time > 0.0 or health <= 0:
		return false
	stamina -= cost
	attack_kind = kind
	attack_charge = clampf(charge, 0.0, 1.0)
	attack_time = Rules.attack_duration(kind, weapon_type)
	attack_emit_at = attack_time * 0.55
	attack_cooldown = attack_time + (0.07 if kind == "heavy" else 0.06)
	attack_fired = false
	queue_redraw()
	return true

func start_heal() -> bool:
	if health <= 0 or health >= max_health or potions <= 0 or heal_time > 0.0 or attack_time > 0.0 or dodge_time > 0.0:
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
	heal_time = 0.0
	health = maxi(0, health - amount)
	invincible_time = 0.75
	hurt_time = 0.22
	velocity.x = -facing * 165.0
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
	sprite.rotation = -0.08 * facing if attack_time > 0.0 else 0.0
	sprite.flip_h = facing < 0
	sprite.modulate = Color(1.0, 0.55, 0.5) if hurt_time > 0.0 else (Color("#a8e7ad") if heal_time > 0.0 else Color.WHITE)
	sprite.visible = not (invincible_time > 0.0 and fmod(invincible_time, 0.12) < 0.05)
	queue_redraw()

func _draw() -> void:
	if charge_time > 0.18:
		var width := 48.0 + 15.0 * minf(charge_time, 1.0)
		draw_arc(Vector2(0, -47), width, -1.5, 1.5, 14, Color("#e6b967"), 3.0)
	if attack_time > 0.0 and attack_fired:
		var start := Vector2(25 * facing, -67)
		var reach: float = Rules.attack_reach(attack_kind, weapon_type)
		var end := Vector2((reach + 8.0) * facing, -25)
		var trail := Color("#f3b862") if weapon_type == "maul" else (Color("#c6e7d9") if weapon_type == "pike" else Color("#f1dfa8"))
		draw_line(start, end, trail, 7.0 if weapon_type == "maul" else 4.0)
		draw_line(start + Vector2(0, 6), end + Vector2(0, 6), Color("#b88a4c"), 3.0)
