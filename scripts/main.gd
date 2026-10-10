extends Node2D

const Rules = preload("res://scripts/rules.gd")
const Store = preload("res://scripts/save_store.gd")
const Hunter = preload("res://scripts/hunter.gd")
const Catalog = preload("res://scripts/hunt_catalog.gd")
const Moor = preload("res://scripts/moor.gd")
const GameUI = preload("res://scripts/game_ui.gd")
const SpriteHurtbox = preload("res://scripts/sprite_hurtbox.gd")
const BladeSweep = preload("res://scripts/blade_sweep.gd")
const SMALL_ENEMY_STRIKE_REACH := 82.0
const SMALL_ENEMY_STRIKE_HALF_HEIGHT := 28.0

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
var boss_status_buildup := 0.0
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
	ui.hunt_board_pressed.connect(open_hunt_board)
	ui.gear_pressed.connect(open_gear)
	ui.weapon_pressed.connect(choose_weapon)
	ui.forge_pressed.connect(forge_blade)
	ui.coats_pressed.connect(open_coats)
	ui.weapons_pressed.connect(open_weapons)
	ui.coat_pressed.connect(choose_coat)
	ui.tuning_menu_pressed.connect(open_tuning)
	ui.tuning_pressed.connect(choose_tuning)
	ui.blade_command.connect(_on_blade_command)
	ui.counter_command.connect(_on_counter_command)
	ui.twins_command.connect(_on_twins_command)
	ui.pike_command.connect(_on_pike_command)
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
	boss_status_buildup = 0.0
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
	hunter.armor_type = str(progress.get("armor_equipped", "field"))
	hunter.tuning_type = str(progress.get("tuning_equipped", {}).get(hunter.weapon_type, "plain"))
	world.add_child(hunter)
	hunter.struck.connect(_on_hunter_struck)
	hunter.blade_swept.connect(_on_blade_swept)
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
	SpriteHurtbox.local_rectangles(boss.sprite.texture)
	for foe in rats: SpriteHurtbox.local_rectangles(foe.sprite.texture)
	boss.attacked.connect(_on_boss_attack)
	boss.armor_shattered.connect(_on_armor_broken)
	boss.part_broken.connect(_on_part_broken)
	boss.wound_opened.connect(_on_wound_opened)
	boss.defeated.connect(_on_boss_defeated)
	ui.show_hunt(selected_hunt, hunter.weapon_type)
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

func _on_blade_command(command: String) -> void:
	if mode != "hunt" or hunter == null or not is_instance_valid(hunter) or hunter.weapon_type != "blade":
		return
	match command:
		"cut":
			hunter.request_action("light")
		"lift":
			hunter.request_action("light", true)
		"dodge":
			hunter.start_dodge()
		"charge_start":
			hunter.start_blade_charge()
		"charge_release":
			hunter.release_blade_charge()
		"brace":
			hunter.brace_blade_charge()
		"anvil_rise":
			hunter.start_anvil_rise()

func _on_counter_command(command: String) -> void:
	if mode != "hunt" or hunter == null or not is_instance_valid(hunter) or hunter.weapon_type != "counter":
		return
	match command:
		"cut":
			hunter.request_action("light")
		"lift":
			hunter.request_action("light", true)
		"dodge":
			hunter.start_dodge()
		"focus_arc":
			hunter.request_action("heavy")
		"counter_guard":
			hunter.request_action("special")

func _on_twins_command(command: String) -> void:
	if mode != "hunt" or hunter == null or not is_instance_valid(hunter) or hunter.weapon_type != "twins":
		return
	match command:
		"cut":
			hunter.request_action("light")
		"rush":
			hunter.request_action("light", true)
		"dodge":
			hunter.start_dodge()
		"fan":
			hunter.request_action("heavy")
		"overdrive":
			hunter.request_action("special")

func _on_pike_command(command: String) -> void:
	if mode != "hunt" or hunter == null or not is_instance_valid(hunter) or hunter.weapon_type != "pike":
		return
	match command:
		"thrust":
			hunter.request_action("light")
		"drive":
			hunter.request_action("light", true)
		"hop":
			hunter.start_dodge()
		"bash":
			hunter.request_action("heavy")
		"guard":
			hunter.request_action("special")

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

func open_hunt_board() -> void:
	if mode != "camp":
		return
	mode = "hunt_board"
	ui.show_hunt_board(progress)

func open_coats() -> void:
	if mode != "gear":
		return
	mode = "coats"
	ui.show_coats(progress)

func open_weapons() -> void:
	if mode not in ["coats", "tuning"]:
		return
	mode = "gear"
	ui.show_gear(progress)

func open_tuning() -> void:
	if mode != "gear":
		return
	mode = "tuning"
	ui.show_tuning(progress)

func choose_tuning(tuning_id: String) -> void:
	if mode != "tuning" or tuning_id not in Rules.tuning_ids():
		return
	var weapon_id := str(progress.get("equipped", "blade"))
	var all_owned: Dictionary = progress["weapon_tunings"]
	var owned: Dictionary = all_owned[weapon_id]
	if not bool(owned.get(tuning_id, false)):
		if not Rules.can_craft_tuning(progress, weapon_id, tuning_id):
			return
		var recipe := Rules.tuning_recipe(tuning_id)
		progress["parts"] = int(progress["parts"]) - int(recipe.get("parts", 0))
		var material := str(recipe.get("material", ""))
		if not material.is_empty():
			var inventory: Dictionary = progress["inventory"]
			inventory[material] = int(inventory.get(material, 0)) - int(recipe.get("count", 0))
		owned[tuning_id] = true
		_play_sound("forge")
	var equipped: Dictionary = progress["tuning_equipped"]
	equipped[weapon_id] = tuning_id
	_save()
	ui.show_tuning(progress)

func choose_coat(coat_id: String) -> void:
	if mode != "coats" or coat_id not in Rules.coat_ids():
		return
	var owned: Dictionary = progress["armor_owned"]
	if not bool(owned.get(coat_id, false)):
		if not Rules.can_craft_coat(progress, coat_id):
			return
		var recipe := Rules.coat_recipe(coat_id)
		progress["parts"] = int(progress["parts"]) - int(recipe["parts"])
		var inventory: Dictionary = progress["inventory"]
		var material := str(recipe["material"])
		inventory[material] = int(inventory.get(material, 0)) - int(recipe["count"])
		owned[coat_id] = true
		_play_sound("forge")
	progress["armor_equipped"] = coat_id
	_save()
	ui.show_coats(progress)

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
	if hunter.weapon_type == "blade": return
	var landed := false
	var impact := Rules.action_impact(kind, hunter.weapon_type)
	var part_kind := "heavy" if impact in ["heavy", "pierce", "blunt"] else "light"
	for rat in rats:
		if not is_instance_valid(rat) or rat.health <= 0:
			continue
		if hunter.can_strike_point(rat.global_position, kind, reach, 40.0, 86.0, 15.0):
			var tuned_damage := Rules.tuned_damage(damage, hunter.weapon_type, hunter.tuning_type, 1.0)
			rat.receive_hit(tuned_damage)
			landed = true
	if boss != null and is_instance_valid(boss) and boss.health > 0:
		var target_position: Vector2 = boss.part_world_position(selected_part)
		if hunter.can_strike_point(target_position, kind, reach, 40.0, 155.0, 25.0):
			boss.receive_hit(_tuned_damage_for_boss(damage), part_kind, selected_part)
			_apply_tuning_status()
			boss.queue_redraw()
			landed = true
	if landed:
		hunter.confirm_hit(kind)
		_play_sound("hit")

func _on_blade_swept(damage: int, kind: String) -> void:
	if mode != "hunt" or hunter == null or hunter.weapon_type != "blade": return
	var pieces: Array[PackedVector2Array] = hunter.blade_sweep_polygons()
	if pieces.is_empty(): return
	var landed := false
	for foe in rats:
		if not is_instance_valid(foe) or foe.health <= 0 or hunter.blade_hit_targets.has(foe.get_instance_id()): continue
		if BladeSweep.overlaps_sprite(pieces, foe.sprite) and hunter.consume_blade_hit(foe):
			foe.receive_hit(Rules.tuned_damage(damage, hunter.weapon_type, hunter.tuning_type, 1.0))
			print("GS_CONTACT kind=%s target=%d damage=%d" % [kind, foe.get_instance_id(), damage])
			landed = true
	if boss != null and is_instance_valid(boss) and boss.health > 0 and not hunter.blade_hit_targets.has(boss.get_instance_id()):
		if BladeSweep.overlaps_sprite(pieces, boss.sprite) and hunter.consume_blade_hit(boss):
			boss.receive_hit(_tuned_damage_for_boss(damage), "heavy", selected_part)
			print("GS_CONTACT kind=%s target=%d damage=%d" % [kind, boss.get_instance_id(), damage])
			_apply_tuning_status()
			boss.queue_redraw()
			landed = true
	if landed:
		hunter.confirm_hit(kind)
		_play_sound("hit")

func _tuned_damage_for_boss(base_damage: int) -> int:
	if hunter == null:
		return base_damage
	var element := Rules.tuning_element(hunter.tuning_type)
	var matchup := 1.0 if element in ["", "raw"] else Catalog.element_multiplier(selected_hunt, element)
	return Rules.tuned_damage(base_damage, hunter.weapon_type, hunter.tuning_type, matchup)

func _apply_tuning_status() -> bool:
	if hunter == null or boss == null or not is_instance_valid(boss) or boss.health <= 0:
		return false
	var gain := Rules.tuning_status_gain(hunter.weapon_type, hunter.tuning_type, Catalog.status_multiplier(selected_hunt, "snare"))
	if gain <= 0.0:
		return false
	boss_status_buildup += gain
	if boss_status_buildup < Catalog.status_threshold(selected_hunt, "snare"):
		return false
	boss_status_buildup = 0.0
	if boss.has_method("apply_status") and boss.apply_status("snare", 1.35):
		ui.flash("snared")
		return true
	return false

func _on_rat_attack(damage: int, rat: Node2D) -> void:
	if mode == "hunt" and hunter != null and is_instance_valid(rat) and hunter.health > 0:
		var horizontal_gap := absf(rat.global_position.x - hunter.global_position.x)
		var vertical_gap := absf(rat.global_position.y - hunter.global_position.y)
		if horizontal_gap < SMALL_ENEMY_STRIKE_REACH and vertical_gap <= SMALL_ENEMY_STRIKE_HALF_HEIGHT:
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
		var attack_width := reach + (16.0 if kind == "rush" or kind == "charge" else 72.0)
		var attack_rect := Rect2(boss.global_position + Vector2(-attack_width, -125.0), Vector2(attack_width * 2.0, 250.0))
		if hunter.try_anvil_clash(attack_rect):
			_play_sound("hit")
			return
		hunter.take_hit(damage)
		_play_sound("hit")

func _on_armor_broken() -> void:
	_play_sound("break")
	match selected_hunt:
		"briarwood": ui.flash("antler_break")
		"ashbell": ui.flash("bell_break")
		_: ui.flash("break")

func _on_part_broken(part_id: String) -> void:
	var primary_part := "vent"
	if selected_hunt == "briarwood":
		primary_part = "antler"
	elif selected_hunt == "ashbell":
		primary_part = "chamber"
	if part_id != primary_part:
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
	var trophy := Catalog.trophy_reward(selected_hunt, boss.armor_broken)
	if not trophy.is_empty():
		var inventory: Dictionary = progress["inventory"]
		var trophy_id := str(trophy["id"])
		inventory[trophy_id] = int(inventory.get(trophy_id, 0)) + int(trophy["count"])
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
	ui.show_result(true, reward, str(trophy.get("id", "")), int(trophy.get("count", 0)))

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
