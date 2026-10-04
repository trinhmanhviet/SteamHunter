extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	game.progress["parts"] = 12
	game.open_gear()
	_check(game.mode == "gear", "camp opens gear screen")
	game.choose_weapon("pike")
	_check(game.progress["parts"] == 7, "buying pike spends five parts")
	_check(game.progress["weapons"]["pike"] and game.progress["equipped"] == "pike", "buying pike equips it")
	game.choose_weapon("maul")
	_check(game.progress["parts"] == 0 and game.progress["equipped"] == "maul", "maul can be forged")
	game.choose_weapon("pike")
	_check(game.progress["parts"] == 0 and game.progress["equipped"] == "pike", "switching owned weapons costs nothing")
	game.progress["parts"] = 3
	game.forge_blade()
	_check(game.progress["forge_level"] == 1 and game.progress["parts"] == 0, "forge rank upgrades the equipped loadout")
	game.start_hunt("briarwood")
	await physics_frame
	_check(game.hunter.weapon_type == "pike", "hunt uses equipped weapon")
	_check(game.hunter.forge_level == 1, "hunt carries forge rank into combat")
	game.hunter.weapon_type = "blade"
	game._on_blade_command("cut")
	_check(game.hunter.current_action == "draw_hew", "combat-stick cut routes into Great Cleaver draw hew")
	game.hunter.advance_action(game.hunter.attack_time + 0.01)
	game.hunter.attack_cooldown = 0.0
	game._on_blade_command("charge_start")
	game.hunter.advance_blade_charge(0.8)
	game._on_blade_command("charge_release")
	_check(game.hunter.current_action == "charged_hew" and game.hunter.attack_charge > 0.65, "combat-stick charge routes into a powered Great Cleaver cut")
	game.hunter.advance_action(game.hunter.attack_time + 0.01)
	game.hunter.attack_cooldown = 0.0
	game.hunter.weapon_type = "counter"
	game.hunter.weapon_resource = 100.0
	game.hunter.weapon_drawn = false
	game._on_counter_command("cut")
	_check(game.hunter.current_action == "draw_cut", "combat-stick cut routes into Warden Sabre draw cut")
	game.hunter.advance_action(game.hunter.attack_time + 0.01)
	game.hunter.attack_cooldown = 0.0
	game._on_counter_command("counter_guard")
	_check(game.hunter.current_action == "counter_guard", "downward held combat-stick route opens Counter Guard")
	game.queue_free()
	await process_frame
	quit()

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		quit(1)
