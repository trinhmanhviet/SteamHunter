extends Node2D

const Rules = preload("res://scripts/rules.gd")
const Store = preload("res://scripts/save_store.gd")
const Hunter = preload("res://scripts/hunter.gd")
const Catalog = preload("res://scripts/hunt_catalog.gd")
const Moor = preload("res://scripts/moor.gd")
const GameUI = preload("res://scripts/game_ui.gd")

var mode := "camp"
var selected_hunt := "moor"
var active_hunt: Dictionary = {}
var save_enabled := true
var progress: Dictionary = Store.defaults()
var camp_back: Sprite2D
var camp_camera: Camera2D
var world: Node2D
var hunter: CharacterBody2D
var boss: StaticBody2D
var rats: Array[Node2D] = []
var pickups: Array[Vector2] = []
var herbs: Array[Vector2] = []
var herb_sprites: Array[Sprite2D] = []
var hunt_parts := 0
var hunt_elapsed := 0.0
var selected_part := ""
var ui: CanvasLayer
var music: AudioStreamPlayer

func _ready() -> void:
	if save_enabled:
		progress = Store.load_progress()
	var view_size := _logical_view_size()
	music = AudioStreamPlayer.new()
	music.volume_db = -17.0
	add_child(music)
	_play_music("camp")
	camp_back = Sprite2D.new()
	camp_back.texture = load("res://art/camp_back.png")
	camp_back.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cover_scale: float = maxf(view_size.x / camp_back.texture.get_width(), view_size.y / camp_back.texture.get_height())
	camp_back.scale = Vector2.ONE * cover_scale
	camp_back.position = view_size / 2.0
	camp_back.z_index = -10
	add_child(camp_back)
	camp_camera = Camera2D.new()
	camp_camera.position = view_size / 2.0
	add_child(camp_camera)
	camp_camera.make_current()
	ui = GameUI.new()
	add_child(ui)
	ui.set_language(str(progress["language"]))
	ui.hunt_pressed.connect(start_hunt)
	ui.gear_pressed.connect(open_gear)
	ui.weapon_pressed.connect(choose_weapon)
	ui.forge_pressed.connect(forge_blade)
	ui.language_pressed.connect(switch_language)
	ui.retry_pressed.connect(start_hunt)
	ui.camp_pressed.connect(return_to_camp)
	ui.show_camp(progress)

func _logical_view_size() -> Vector2:
	var reference := Vector2(960, 540)
	var visible_size := get_viewport().get_visible_rect().size
	if visible_size.y <= 0.0:
		return reference
	return Vector2(maxf(reference.x, reference.y * visible_size.x / visible_size.y), reference.y)

func start_hunt(hunt_id: String = "") -> void:
	get_tree().paused = false
	_clear_hunt()
	if hunt_id in Catalog.ids():
		selected_hunt = hunt_id
	active_hunt = Catalog.get_hunt(selected_hunt)
	mode = "hunt"
	_play_music("hunt")
	hunt_parts = 0
	hunt_elapsed = 0.0
	herbs.clear()
	herb_sprites.clear()
	for at_x in active_hunt["herb_x"]:
		herbs.append(Vector2(float(at_x), Moor.GROUND_Y - 28.0))
	camp_back.visible = false
	world = Moor.new()
	world.biome = str(active_hunt["biome"])
	add_child(world)
	for at in herbs:
		var herb_sprite := Sprite2D.new()
		herb_sprite.texture = load("res://art/healing_herb.png")
		herb_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		herb_sprite.scale = Vector2(38.0 / herb_sprite.texture.get_width(), 43.0 / herb_sprite.texture.get_height())
		herb_sprite.position = at
		world.add_child(herb_sprite)
		herb_sprites.append(herb_sprite)
	hunter = Hunter.new()
	hunter.position = Vector2(250, Moor.GROUND_Y)
	hunter.forge_level = int(progress["forge_level"])
	hunter.weapon_type = str(progress["equipped"])
	world.add_child(hunter)
	hunter.struck.connect(_on_hunter_struck)
	hunter.healed.connect(_on_hunter_healed)
	hunter.died.connect(_on_hunter_died)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -198)
	camera.limit_left = 0
	camera.limit_right = int(Moor.WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 540
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
	hunter.add_child(camera)
	camera.make_current()
	var small_script: Script = active_hunt["small_script"]
	for at_x in active_hunt["small_x"]:
		var rat: Node2D = small_script.new()
		rat.position = Vector2(float(at_x), Moor.GROUND_Y)
		rat.target = hunter
		world.add_child(rat)
		rat.attacked.connect(_on_rat_attack.bind(rat))
		rat.defeated.connect(_on_rat_defeated)
		rats.append(rat)
	var boss_script: Script = active_hunt["boss_script"]
	boss = boss_script.new()
	boss.position = Vector2(float(active_hunt["boss_x"]), Moor.GROUND_Y)
	boss.target = hunter
	selected_part = str(boss.part_ids()[0])
	boss.selected_part = selected_part
	world.add_child(boss)
	boss.attacked.connect(_on_boss_attack)
	boss.armor_shattered.connect(_on_armor_broken)
	boss.part_broken.connect(_on_part_broken)
	boss.wound_opened.connect(_on_wound_opened)
	boss.defeated.connect(_on_boss_defeated)
	ui.show_hunt(selected_hunt)
	queue_redraw()

func _process(_delta: float) -> void:
	if mode == "hunt" and boss != null and is_instance_valid(boss):
		if Input.is_action_just_pressed("cycle_target"):
			cycle_target_part()
		ui.update_target(selected_part, boss.part_status(selected_part))

func cycle_target_part() -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var ids: Array = boss.part_ids()
	if ids.is_empty():
		return
	var current_index := ids.find(selected_part)
	selected_part = str(ids[(current_index + 1) % ids.size()])
	boss.selected_part = selected_part
	ui.update_target(selected_part, boss.part_status(selected_part))

func return_to_camp() -> void:
	get_tree().paused = false
	_clear_hunt()
	mode = "camp"
	_play_music("camp")
	camp_back.visible = true
	camp_camera.make_current()
	ui.show_camp(progress)
	queue_redraw()

func open_gear() -> void:
	if mode != "camp":
		return
	mode = "gear"
	ui.show_gear(progress)

func choose_weapon(weapon_id: String) -> void:
	if mode != "gear" or weapon_id not in Rules.weapon_ids():
		return
	var owned: Dictionary = progress["weapons"]
	if not bool(owned[weapon_id]):
		var cost: int = Rules.weapon_cost(weapon_id)
		if int(progress["parts"]) < cost:
			return
		progress["parts"] = int(progress["parts"]) - cost
		owned[weapon_id] = true
		_play_sound("forge")
	progress["equipped"] = weapon_id
	_save()
	ui.show_gear(progress)

func forge_blade() -> void:
	var level: int = int(progress["forge_level"])
	var cost: int = Rules.forge_cost(level)
	if level >= 3 or int(progress["parts"]) < cost:
		return
	progress["parts"] = int(progress["parts"]) - cost
	progress["forge_level"] = level + 1
	_play_sound("forge")
	_save()
	if mode == "gear":
		ui.show_gear(progress)
	else:
		ui.show_camp(progress)

func switch_language() -> void:
	progress["language"] = "vi" if progress["language"] == "en" else "en"
	ui.set_language(str(progress["language"]))
	_save()
	ui.show_camp(progress)

func _clear_hunt() -> void:
	for rat in rats:
		if is_instance_valid(rat):
			rat.queue_free()
	rats.clear()
	pickups.clear()
	herbs.clear()
	herb_sprites.clear()
	if world != null and is_instance_valid(world):
		world.queue_free()
	world = null
	hunter = null
	boss = null

func _save() -> void:
	if save_enabled:
		Store.save_progress(progress)

func _play_music(place: String) -> void:
	var track: AudioStreamWAV = load("res://audio/" + place + "_loop.wav")
	track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream = track
	music.play()

func _play_sound(cue: String) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = load("res://audio/" + cue + ".wav")
	player.volume_db = -7.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _on_hunter_struck(damage: int, reach: float, kind: String) -> void:
	if mode != "hunt" or hunter == null:
		return
	_play_sound("swing")
	var landed := false
	var impact := Rules.action_impact(kind, hunter.weapon_type)
	var part_kind := "heavy" if impact in ["heavy", "pierce", "blunt"] else "light"
	for rat in rats:
		if not is_instance_valid(rat) or rat.health <= 0:
			continue
		var dx: float = rat.global_position.x - hunter.global_position.x
		if dx * hunter.facing >= -15.0 and absf(dx) < reach + 40.0 and absf(rat.global_position.y - hunter.global_position.y) < 86.0:
			rat.receive_hit(damage)
			landed = true
	if boss != null and is_instance_valid(boss) and boss.health > 0:
		var dx: float = boss.global_position.x - hunter.global_position.x
		if dx * hunter.facing >= -25.0 and absf(dx) < reach + 95.0 and absf(boss.global_position.y - hunter.global_position.y) < 115.0:
			var target_position: Vector2 = boss.part_world_position(selected_part)
			var target_dx := target_position.x - hunter.global_position.x
			if target_dx * hunter.facing >= -25.0 and absf(target_dx) < reach + 40.0 and absf(target_position.y - hunter.global_position.y) < 155.0:
				boss.receive_hit(damage, part_kind, selected_part)
				boss.queue_redraw()
				landed = true
	if landed:
		hunter.confirm_hit(kind)
		_play_sound("hit")

func _on_rat_attack(damage: int, rat: Node2D) -> void:
	if mode == "hunt" and hunter != null and is_instance_valid(rat) and hunter.health > 0:
		if absf(rat.global_position.x - hunter.global_position.x) < 82.0:
			hunter.take_hit(damage)
			_play_sound("hit")

func _on_rat_defeated(at_position: Vector2) -> void:
	pickups.append(at_position + Vector2(0, -42))
	queue_redraw()

func _on_hunter_healed() -> void:
	_play_sound("pickup")
	ui.flash("healed")

func _on_boss_attack(kind: String, damage: int, reach: float) -> void:
	if mode != "hunt" or hunter == null or boss == null or hunter.health <= 0:
		return
	var dx: float = hunter.global_position.x - boss.global_position.x
	var in_range := absf(dx) < reach + (100.0 if kind == "burst" or kind == "thorns" else 72.0)
	if kind == "rush" or kind == "charge":
		in_range = absf(dx) < reach + 16.0
	if in_range and absf(hunter.global_position.y - boss.global_position.y) < 125.0:
		hunter.take_hit(damage)
		_play_sound("hit")

func _on_armor_broken() -> void:
	_play_sound("break")
	ui.flash("antler_break" if selected_hunt == "briarwood" else "break")

func _on_part_broken(part_id: String) -> void:
	if part_id != ("antler" if selected_hunt == "briarwood" else "vent"):
		_play_sound("break")
		ui.flash("part_broken")

func _on_wound_opened(_part_id: String) -> void:
	ui.flash("wound_open")

func _on_boss_defeated() -> void:
	if mode != "hunt":
		return
	var extra_breaks := maxi(0, int(boss.body_parts.broken_count()) - (1 if boss.armor_broken else 0))
	var reward: int = Catalog.reward(selected_hunt, boss.armor_broken, extra_breaks) + hunt_parts
	progress["parts"] = int(progress["parts"]) + reward
	progress["hunts_won"] = int(progress["hunts_won"]) + 1
	var completed: Array = progress["completed_hunts"]
	if selected_hunt not in completed:
		completed.append(selected_hunt)
	var records: Dictionary = progress["hunt_records"]
	var record: Dictionary = records.get(selected_hunt, {"wins": 0, "best_time_ms": 0})
	record["wins"] = int(record.get("wins", 0)) + 1
	var elapsed_ms := maxi(1, roundi(hunt_elapsed * 1000.0))
	var previous_best := int(record.get("best_time_ms", 0))
	record["best_time_ms"] = elapsed_ms if previous_best == 0 else mini(previous_best, elapsed_ms)
	records[selected_hunt] = record
	_save()
	mode = "result"
	_play_sound("forge")
	hunter.has_control = false
	ui.show_result(true, reward)

func _on_hunter_died() -> void:
	if mode != "hunt":
		return
	mode = "result"
	ui.show_result(false, 0)

func _physics_process(_delta: float) -> void:
	if mode != "hunt" or hunter == null or ui == null:
		return
	hunt_elapsed += _delta
	ui.update_hud(hunter, boss, hunt_parts, hunter.global_position.x > 1900.0)
	for i in range(pickups.size() - 1, -1, -1):
		if hunter.global_position.distance_to(pickups[i]) < 72.0:
			hunt_parts += 1
			_play_sound("pickup")
			pickups.remove_at(i)
			ui.flash("collected")
			queue_redraw()
	for i in range(herbs.size() - 1, -1, -1):
		if hunter.global_position.distance_to(herbs[i]) < 56.0 and hunter.add_potion():
			herb_sprites[i].queue_free()
			herb_sprites.remove_at(i)
			herbs.remove_at(i)
			_play_sound("pickup")
			ui.flash("herb")
			queue_redraw()

func _draw() -> void:
	for at in pickups:
		draw_circle(at, 12.0, Color("#f2c879"))
		draw_arc(at, 15.0, 0.0, TAU, 20, Color("#653c2f"), 4.0)
		draw_line(at + Vector2(-7, 0), at + Vector2(7, 0), Color("#874e31"), 3.0)
