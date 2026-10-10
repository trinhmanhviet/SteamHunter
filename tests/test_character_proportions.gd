extends SceneTree

const Hunter = preload("res://scripts/hunter.gd")
const Rat = preload("res://scripts/mire_rat.gd")
const Boar = preload("res://scripts/bristlehog.gd")
const Cinderback = preload("res://scripts/cinderback.gd")
const Thornhart = preload("res://scripts/thornhart.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for weapon_id in ["blade", "pike", "maul"]:
		var hunter := Hunter.new()
		hunter.weapon_type = weapon_id
		root.add_child(hunter)
		_check(_height(hunter.sprite) <= 92.0, weapon_id + " hunter fits the smaller screen proportion")
		_check(_body_height(hunter) <= 75.0, weapon_id + " collision follows the smaller hunter")
		hunter.queue_free()
	for beast_script in [Rat, Boar]:
		var beast: Node2D = beast_script.new()
		root.add_child(beast)
		_check(_height(beast.sprite) <= 51.0, "small beast fits the screen proportion")
		beast.queue_free()
	for boss_script in [Cinderback, Thornhart]:
		var boss: StaticBody2D = boss_script.new()
		root.add_child(boss)
		_check(_height(boss.sprite) <= 136.0, "large beast leaves room for platform play")
		_check(_body_height(boss) <= 92.0, "large beast collision follows its art")
		boss.queue_free()
	quit(1 if failures > 0 else 0)

func _height(sprite: Sprite2D) -> float:
	return (sprite.region_rect.size.y if sprite.region_enabled else sprite.texture.get_height()) * sprite.scale.y

func _body_height(actor: Node) -> float:
	return (actor.get_child(0) as CollisionShape2D).shape.size.y

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
