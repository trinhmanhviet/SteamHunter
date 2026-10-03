extends Node2D

signal attacked(damage: int)
signal defeated(at_position: Vector2)

var health := 26
var patrol_center := 0.0
var patrol_width := 160.0
var facing := 1
var attack_wait := 1.5
var hit_flash := 0.0
var target: Node2D
var sprite: Sprite2D
var time := 0.0

func _ready() -> void:
	patrol_center = position.x
	sprite = Sprite2D.new()
	sprite.texture = load("res://art/mire_rat.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * (38.0 / sprite.texture.get_height())
	sprite.position = Vector2(0, -19)
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	time += delta
	hit_flash = maxf(0.0, hit_flash - delta)
	attack_wait = maxf(0.0, attack_wait - delta)
	var close := target != null and is_instance_valid(target) and absf(target.global_position.x - global_position.x) < 230.0
	if close:
		facing = -1 if target.global_position.x < global_position.x else 1
		if absf(target.global_position.x - global_position.x) > 56.0:
			position.x += facing * 78.0 * delta
		elif attack_wait <= 0.0:
			attacked.emit(11)
			attack_wait = 1.3
	else:
		if position.x > patrol_center + patrol_width:
			facing = -1
		elif position.x < patrol_center - patrol_width:
			facing = 1
		position.x += facing * 43.0 * delta
	if sprite != null:
		sprite.flip_h = facing < 0
		sprite.position.y = -19.0 + sin(time * 11.0) * 1.4
		sprite.modulate = Color("#ffc19b") if hit_flash > 0.0 else Color.WHITE

func receive_hit(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	hit_flash = 0.16
	if health == 0:
		defeated.emit(global_position)
		queue_free()
