extends Node2D

signal attacked(damage: int)
signal defeated(at_position: Vector2)

var health := 34
var patrol_center := 0.0
var patrol_width := 190.0
var facing := -1
var attack_wait := 1.1
var hit_flash := 0.0
var target: Node2D
var sprite: Sprite2D
var time := 0.0

func _ready() -> void:
	patrol_center = position.x
	sprite = Sprite2D.new()
	sprite.texture = load("res://art/bristlehog.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * (50.0 / sprite.texture.get_height())
	sprite.position = Vector2(0, -25)
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	time += delta
	hit_flash = maxf(0.0, hit_flash - delta)
	attack_wait = maxf(0.0, attack_wait - delta)
	var close := target != null and is_instance_valid(target) and absf(target.global_position.x - global_position.x) < 260.0
	if close:
		facing = -1 if target.global_position.x < global_position.x else 1
		if absf(target.global_position.x - global_position.x) > 62.0:
			position.x += facing * 112.0 * delta
		elif attack_wait <= 0.0:
			attacked.emit(14)
			attack_wait = 1.0
	else:
		if position.x > patrol_center + patrol_width:
			facing = -1
		elif position.x < patrol_center - patrol_width:
			facing = 1
		position.x += facing * 49.0 * delta
	if sprite != null:
		sprite.flip_h = facing > 0
		sprite.position.y = -25.0 + sin(time * 12.0) * 1.5
		sprite.modulate = Color("#ffd0aa") if hit_flash > 0.0 else Color.WHITE

func receive_hit(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - maxi(0, amount))
	hit_flash = 0.16
	if health == 0:
		defeated.emit(global_position)
		queue_free()
