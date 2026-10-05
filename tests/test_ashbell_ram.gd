extends SceneTree

const AshbellRam = preload("res://scripts/ashbell_ram.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ram = AshbellRam.new()
	root.add_child(ram)
	_check(ram.max_health == 460 and ram.health == 460, "Ashbell Ram has third-hunt durability")
	_check(ram.attack_ids() == ["charge", "horn_swing", "toll_blast", "hoof_quake", "rebound"], "ram exposes five readable attacks")
	for attack_id in ram.attack_ids():
		var profile: Dictionary = ram.attack_profile(attack_id)
		_check(int(profile.get("damage", 0)) > 0 and float(profile.get("reach", 0.0)) > 0.0, attack_id + " has a damaging profile")
	_check(ram.part_ids() == ["horn", "chamber"], "ram has two independently targetable parts")
	_check(ram.part_world_position("horn") != ram.part_world_position("chamber"), "part markers occupy distinct body regions")
	_check(ram.sprite.texture.resource_path.ends_with("ashbell_ram.png"), "generated Ashbell art is active")

	var intact_charge: Dictionary = ram.attack_profile("charge")
	var intact_swing: Dictionary = ram.attack_profile("horn_swing")
	ram.receive_hit(90, "heavy", "horn")
	_check(ram.part_status("horn")["broken"] and not ram.armor_broken, "horn breaks independently from the chamber")
	_check(ram.attack_profile("charge")["speed"] < intact_charge["speed"], "broken horn slows the charge")
	_check(ram.attack_profile("horn_swing")["reach"] < intact_swing["reach"], "broken horn shortens the swing")
	_check(not ram.can_rebound(), "broken horn disables the rebound combo")
	ram.receive_hit(110, "heavy", "chamber")
	_check(ram.state == "knockdown" and ram.state_time >= 1.5, "breaking both Ashbell parts knocks it down")

	var chamber_ram = AshbellRam.new()
	root.add_child(chamber_ram)
	chamber_ram.receive_hit(110, "heavy", "chamber")
	_check(chamber_ram.armor_broken and chamber_ram.part_status("chamber")["broken"], "chamber break opens the armored core")
	_check(chamber_ram.attack_profile("toll_blast")["damage"] == 0, "broken chamber disables the resonance blast")
	chamber_ram.attack_count = 2
	_check(chamber_ram.next_attack_for_distance(90.0) != "toll_blast", "disabled blast is removed from selection")

	var phase_ram = AshbellRam.new()
	root.add_child(phase_ram)
	phase_ram.receive_hit(235, "light", "horn")
	_check(phase_ram.phase == 2, "ram enrages below half health")
	phase_ram.attack_count = 4
	phase_ram.state = "strike"
	phase_ram.advance_state()
	_check(phase_ram.state == "exhausted" and phase_ram.state_time >= 1.5, "five attacks force a punishable exhaustion")

	for beast in [ram, chamber_ram, phase_ram]:
		beast.queue_free()
	quit(1 if failures > 0 else 0)

func _check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: " + message)
		failures += 1
