extends SceneTree

var failures := 0
var checks := 0

class Target extends Node2D:
	var health := 100
	var sprite: Sprite2D
	func _ready() -> void:
		var image := Image.create(16,16,false,Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		for y in range(4,12):
			for x in range(4,12): image.set_pixel(x,y,Color.WHITE)
		sprite = Sprite2D.new()
		sprite.texture = ImageTexture.create_from_image(image)
		add_child(sprite)
	func receive_hit(amount: int) -> void:
		health -= amount

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func centroid(polygon: PackedVector2Array) -> Vector2:
	var point := Vector2.ZERO
	for vertex in polygon: point += vertex
	return point / polygon.size()

func fresh(hunter) -> void:
	hunter.current_action = ""
	hunter.charge_time = 0
	hunter.hit_stop_time = 0
	hunter.stamina = 100
	hunter.attack_cooldown = 0
	check(hunter.start_action("draw_hew"), "new physical swing starts")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	game.start_hunt("moor")
	var hunter = game.hunter
	check(hunter.has_signal("blade_swept"), "Great Cleaver must publish active physical blade sweeps")
	if not hunter.has_signal("blade_swept"):
		game.queue_free()
		quit(1)
		return
	hunter.set_physics_process(false)
	game.boss.set_physics_process(false)
	game.boss.position.x += 2000
	for foe in game.rats:
		foe.set_physics_process(false)
		foe.position.x += 2000
	game.rats.clear()
	var foe := Target.new()
	game.world.add_child(foe)
	game.rats.append(foe)
	foe.global_position = hunter.global_position + Vector2(8,-25)
	game._on_hunter_struck(100,999,"draw_hew")
	check(foe.health == 100, "the old radius callback cannot damage a blade target")
	hunter.start_blade_charge()
	hunter.advance_blade_charge(.8)
	game._on_blade_swept(100,"charged_hew")
	check(foe.health == 100, "charge has no active damage collider")
	fresh(hunter)
	hunter.advance_action(.31)
	check(foe.health == 100, "near torso inside the former padded box must miss")
	fresh(hunter)
	foe.global_position = centroid(hunter.blade_polygon_at(hunter.attack_emit_at))
	hunter.advance_action(hunter.attack_emit_at + .005)
	check(foe.health < 100, "visible blade contact damages target")
	var first := foe.health
	hunter.advance_action(.02)
	check(foe.health == first, "one target cannot be hit twice during the same swing")
	hunter.advance_action(.5)
	check(foe.health == first, "resting blade in recovery causes no extra damage")
	foe.health = 100
	fresh(hunter)
	var old_ground := centroid(hunter.blade_polygon_at(hunter.attack_emit_at))
	foe.global_position = old_ground
	hunter.global_position.y -= 80
	hunter.advance_action(.31)
	check(foe.health == 100, "airborne sword above a foe must miss")
	hunter.global_position.y += 80
	hunter.facing = -1
	fresh(hunter)
	foe.global_position = centroid(hunter.blade_polygon_at(hunter.attack_emit_at))
	hunter.advance_action(.31)
	check(foe.health < 100, "left-facing sword collider follows the rendered blade")
	print("BLADE_CONTACT_FLOW: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	quit(1 if failures else 0)
