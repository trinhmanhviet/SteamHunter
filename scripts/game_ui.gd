extends CanvasLayer

signal hunt_pressed(hunt_id: String)
signal gear_pressed
signal weapon_pressed(weapon_id: String)
signal forge_pressed
signal language_pressed
signal retry_pressed
signal camp_pressed
signal resume_pressed

const Words = preload("res://scripts/words.gd")
const Rules = preload("res://scripts/rules.gd")
const Catalog = preload("res://scripts/hunt_catalog.gd")
const GameStick = preload("res://scripts/virtual_joystick.gd")
const TouchActionButton = preload("res://scripts/touch_action_button.gd")
const REFERENCE_SIZE := Vector2(960, 540)

var language := "en"
var current_hunt := "moor"
var root: Control
var health_fill: ColorRect
var stamina_fill: ColorRect
var resource_fill: ColorRect
var resource_back: ColorRect
var resource_label: Label
var boss_fill: ColorRect
var boss_group: Control
var part_label: Label
var target_label: Label
var potion_label: Label
var flash_label: Label
var flash_time := 0.0
var layout_size := REFERENCE_SIZE

func _ready() -> void:
	var visible_size := get_viewport().get_visible_rect().size
	if visible_size.y > 0.0:
		layout_size = Vector2(maxf(REFERENCE_SIZE.x, REFERENCE_SIZE.y * visible_size.x / visible_size.y), REFERENCE_SIZE.y)
	root = Control.new()
	root.size = layout_size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

func set_language(value: String) -> void:
	language = value if value == "vi" else "en"

func t(key: String) -> String:
	return Words.get_text(language, key)

func show_camp(progress: Dictionary) -> void:
	_clear()
	var right_offset := _right_offset()
	var center_offset := _center_offset()
	_overlay(Color(0.01, 0.04, 0.07, 0.20))
	var camp_title := _label(t("title"), Vector2(318 + center_offset, 24), Vector2(600, 60), 46, Color("#f4d99b"))
	camp_title.name = "CampTitle"
	_label(t("subtitle"), Vector2(319 + center_offset, 81), Vector2(590, 31), 21, Color("#c5d6ca"))
	var hunt_panel := _panel(Rect2(626 + right_offset, 125, 306, 365))
	hunt_panel.name = "HuntSelectPanel"
	_label(t("choose_hunt"), Vector2(648 + right_offset, 141), Vector2(270, 33), 24, Color("#f1cf89"))
	var hunt_scroll := ScrollContainer.new()
	hunt_scroll.position = Vector2(647 + right_offset, 184)
	hunt_scroll.size = Vector2(264, 164)
	hunt_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hunt_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(hunt_scroll)
	var hunt_list := Control.new()
	hunt_list.custom_minimum_size = Vector2(264, Catalog.ids().size() * 82)
	hunt_scroll.add_child(hunt_list)
	var index := 0
	for hunt_id in Catalog.ids():
		var hunt: Dictionary = Catalog.get_hunt(hunt_id)
		var button := _button(t(str(hunt["hunt_name_key"])) + "  ·  " + t(str(hunt["region_key"])), Rect2(0, index * 82, 264, 45), func(): hunt_pressed.emit(hunt_id), hunt_list)
		button.name = "Hunt_" + hunt_id
		button.add_theme_font_size_override("font_size", 16)
		_label(t(str(hunt["tip_key"])), Vector2(1, index * 82 + 47), Vector2(260, 30), 13, Color("#c0d1cc"), hunt_list)
		index += 1
	_button(t("gear_button") + ": " + t(str(progress.get("equipped", "blade")) + "_name"), Rect2(647 + right_offset, 353, 264, 42), func(): gear_pressed.emit())
	_label(t("parts") + ": " + str(progress.get("parts", 0)) + "   •   " + t("level") + ": " + str(int(progress.get("forge_level", 0)) + 1), Vector2(648 + right_offset, 408), Vector2(270, 28), 16, Color("#f1cf89"))
	_label(t("hunt_count").format({"count": progress.get("hunts_won", 0)}), Vector2(648 + right_offset, 440), Vector2(270, 26), 15, Color("#c0d1cc"))
	_button(t("lang"), Rect2(24, 473, 172, 40), func(): language_pressed.emit())
	if not OS.has_feature("mobile"):
		_label(t("controls"), Vector2(20, 510), Vector2(910, 24), 13, Color("#d7d9c1"))

func show_gear(progress: Dictionary) -> void:
	_clear()
	var center_offset := _center_offset()
	_overlay(Color(0.01, 0.03, 0.06, 0.77))
	var gear_panel := _panel(Rect2(30 + center_offset, 26, 900, 488))
	gear_panel.name = "GearPanel"
	_label(t("gear_title"), Vector2(58 + center_offset, 45), Vector2(420, 48), 34, Color("#f1cf89"))
	_label(t("parts") + ": " + str(progress.get("parts", 0)), Vector2(658 + center_offset, 52), Vector2(245, 33), 21, Color("#d9dfc9"))
	var ids := Rules.weapon_ids()
	var weapon_scroll := ScrollContainer.new()
	weapon_scroll.name = "WeaponScroll"
	weapon_scroll.position = Vector2(48 + center_offset, 104)
	weapon_scroll.size = Vector2(864, 324)
	weapon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	weapon_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(weapon_scroll)
	var card_strip := Control.new()
	card_strip.name = "WeaponCards"
	card_strip.custom_minimum_size = Vector2(ids.size() * 290.0 - 18.0, 310.0)
	weapon_scroll.add_child(card_strip)
	for index in range(ids.size()):
		var weapon_id: String = ids[index]
		var weapon_data: Dictionary = Rules.weapon(weapon_id)
		var x := index * 290.0
		_panel(Rect2(x, 0, 272, 310), card_strip)
		var portrait := Sprite2D.new()
		portrait.name = "Portrait_" + weapon_id
		portrait.texture = load(str(weapon_data["art"]))
		portrait.modulate = weapon_data.get("tint", Color.WHITE)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.position = Vector2(x + 136, 95)
		var portrait_scale: float = minf(232.0 / portrait.texture.get_width(), 167.0 / portrait.texture.get_height())
		portrait.scale = Vector2.ONE * portrait_scale
		card_strip.add_child(portrait)
		_label(t(weapon_id + "_name"), Vector2(x + 16, 184), Vector2(240, 34), 22, Color("#f1cf89"), card_strip)
		_label(t(weapon_id + "_desc"), Vector2(x + 16, 217), Vector2(240, 43), 14, Color("#c8d4c7"), card_strip)
		var owned: bool = bool(progress.get("weapons", {}).get(weapon_id, weapon_id == "blade"))
		var equipped: bool = str(progress["equipped"]) == weapon_id
		var cost: int = Rules.weapon_cost(weapon_id)
		var action_text := t("equipped") if equipped else (t("equip") if owned else (t("craft_weapon") if int(progress["parts"]) >= cost else t("need_parts")).format({"cost": cost}))
		var action_button := _button(action_text, Rect2(x + 16, 261, 240, 42), func(): weapon_pressed.emit(weapon_id), card_strip)
		action_button.name = "Weapon_" + weapon_id
		action_button.disabled = equipped or (not owned and int(progress["parts"]) < cost)
	var forge_level: int = int(progress.get("forge_level", 0))
	var forge_cost: int = Rules.forge_cost(forge_level)
	var forge_text := t("forge_max") if forge_level >= 3 else (t("forge_ready") if int(progress["parts"]) >= forge_cost else t("forge_short")).format({"cost": forge_cost})
	var forge_button := _button(forge_text + "  ·  " + t("level") + " " + str(forge_level + 1), Rect2(54 + center_offset, 448, 510, 43), func(): forge_pressed.emit())
	forge_button.disabled = forge_level >= 3 or int(progress["parts"]) < forge_cost
	_button(t("return"), Rect2(705 + center_offset, 448, 200, 43), func(): camp_pressed.emit())

func show_hunt(hunt_id: String = "moor") -> void:
	current_hunt = hunt_id
	_clear()
	var right_offset := _right_offset()
	var center_offset := _center_offset()
	var hunt_hud := _panel(Rect2(18, 16, 312, 126))
	hunt_hud.name = "HuntHud"
	_label(t("health"), Vector2(30, 22), Vector2(68, 24), 15, Color("#f4d99b"))
	_label(t("stamina"), Vector2(30, 61), Vector2(68, 24), 15, Color("#f4d99b"))
	_bar(Rect2(106, 30, 208, 14), Color("#4a262d"))
	health_fill = _bar(Rect2(106, 30, 208, 14), Color("#d95752"))
	_bar(Rect2(106, 69, 208, 14), Color("#304744"))
	stamina_fill = _bar(Rect2(106, 69, 208, 14), Color("#d8b965"))
	resource_label = _label("", Vector2(30, 91), Vector2(72, 22), 13, Color("#d8b8ef"))
	resource_back = _bar(Rect2(106, 99, 208, 12), Color("#342f45"))
	resource_fill = _bar(Rect2(106, 99, 0, 12), Color("#a87bd4"))
	part_label = _label(t("parts") + ": 0", Vector2(20, 149), Vector2(300, 25), 16, Color("#f1cf89"))
	potion_label = _label(t("potion") + ": 2", Vector2(20, 176), Vector2(300, 25), 16, Color("#b9e4a5"))
	boss_group = Control.new()
	boss_group.position = Vector2(359 + center_offset, 19)
	boss_group.size = Vector2(450, 60)
	boss_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boss_group)
	var name_label := Label.new()
	name_label.text = t(str(Catalog.get_hunt(hunt_id)["boss_name_key"]))
	name_label.position = Vector2(0, 0)
	name_label.size = Vector2(450, 27)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", Color("#f1cf89"))
	boss_group.add_child(name_label)
	var back := ColorRect.new()
	back.position = Vector2(0, 32)
	back.size = Vector2(450, 15)
	back.color = Color("#332b34")
	boss_group.add_child(back)
	boss_fill = ColorRect.new()
	boss_fill.position = Vector2(0, 32)
	boss_fill.size = Vector2(450, 15)
	boss_fill.color = Color("#dc8053")
	boss_group.add_child(boss_fill)
	target_label = _label("", Vector2(0, 52), Vector2(450, 22), 13, Color("#e6c889"), boss_group)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_group.visible = false
	flash_label = _label("", Vector2(330 + center_offset, 115), Vector2(420, 52), 31, Color("#ffe3a5"))
	flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var stick := GameStick.new()
	stick.name = "MoveStick"
	stick.position = Vector2.ZERO
	stick.size = layout_size
	root.add_child(stick)
	_action_button(t("drink"), Rect2(646 + right_offset, 330, 66, 66), "heal")
	_action_button(t("jump"), Rect2(620 + right_offset, 421, 78, 78), "jump")
	_action_button(t("special"), Rect2(744 + right_offset, 235, 72, 72), "special")
	_action_button(t("heavy"), Rect2(744 + right_offset, 315, 86, 86), "heavy")
	_action_button(t("dodge"), Rect2(710 + right_offset, 420, 78, 78), "dodge")
	_action_button(t("target_cycle"), Rect2(849 + right_offset, 295, 66, 66), "cycle_target")
	root.get_node("Action_cycle_target").visible = false
	_action_button(t("attack"), Rect2(811 + right_offset, 395, 108, 108), "attack", true)
	var pause_button := _button("Ⅱ", Rect2(899 + right_offset, 16, 43, 40), func(): _show_pause())
	pause_button.name = "PauseButton"

func update_hud(hunter: Node, boss: Node, parts: int, show_boss: bool) -> void:
	if health_fill == null or not is_instance_valid(health_fill):
		return
	health_fill.size.x = 208.0 * float(hunter.health) / float(hunter.max_health)
	stamina_fill.size.x = 208.0 * hunter.stamina / 100.0
	var maximum: float = hunter.resource_max()
	var shows_resource: bool = maximum > 0.0 and not hunter.resource_name().is_empty()
	resource_label.visible = shows_resource
	resource_back.visible = shows_resource
	resource_fill.visible = shows_resource
	if shows_resource:
		resource_label.text = t(hunter.resource_name())
		resource_fill.size.x = 208.0 * clampf(hunter.weapon_resource / maximum, 0.0, 1.0)
	part_label.text = t("parts") + ": " + str(parts)
	potion_label.text = t("potion") + ": " + str(hunter.potions)
	boss_group.visible = show_boss and boss != null and is_instance_valid(boss)
	var target_button := root.get_node_or_null("Action_cycle_target")
	if target_button != null:
		target_button.visible = boss_group.visible
	if target_label != null:
		target_label.visible = boss_group.visible
	if boss_group.visible:
		boss_fill.size.x = 450.0 * float(boss.health) / float(boss.max_health)

func update_target(part_id: String, status: Dictionary) -> void:
	if target_label == null or not is_instance_valid(target_label):
		return
	var name := t("part_" + part_id)
	var detail := t("part_broken") if bool(status.get("broken", false)) else (t("wound_open") if bool(status.get("wounded", false)) else str(status.get("progress", 0)) + "/" + str(status.get("max", 0)))
	target_label.text = t("target") + ": " + name + "  ·  " + detail
	var button := root.get_node_or_null("Action_cycle")
	if button != null:
		button.caption = name
		if button.caption_label != null:
			button.caption_label.text = button.caption
		button.queue_redraw()

func flash(key: String) -> void:
	if flash_label == null or not is_instance_valid(flash_label):
		return
	flash_label.text = t(key)
	flash_time = 1.4

func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time -= delta
		if flash_time <= 0.0 and flash_label != null and is_instance_valid(flash_label):
			flash_label.text = ""

func show_result(victory: bool, parts: int) -> void:
	_clear()
	var center_offset := _center_offset()
	_overlay(Color(0.01, 0.03, 0.06, 0.70))
	var result_panel := _panel(Rect2(238 + center_offset, 119, 484, 318))
	result_panel.name = "ResultPanel"
	_label(t("victory") if victory else t("defeat"), Vector2(263 + center_offset, 145), Vector2(434, 63), 35, Color("#f1cf89"))
	_label(t("victory_body").format({"parts": parts}) if victory else t("defeat_body"), Vector2(270 + center_offset, 223), Vector2(420, 57), 19, Color("#d9e0d1"))
	_button(t("retry"), Rect2(286 + center_offset, 330, 180, 55), func(): retry_pressed.emit())
	_button(t("return"), Rect2(497 + center_offset, 330, 180, 55), func(): camp_pressed.emit())

func _show_pause() -> void:
	for child in root.get_children():
		if child.has_method("release_touch"):
			child.release_touch()
			child.set_process_input(false)
	_overlay(Color(0.0, 0.0, 0.0, 0.58))
	var center_offset := _center_offset()
	var panel := _panel(Rect2(312 + center_offset, 139, 336, 266))
	panel.name = "PausePanel"
	_label(t("pause"), Vector2(353 + center_offset, 161), Vector2(260, 51), 32, Color("#f1cf89"))
	_button(t("resume"), Rect2(365 + center_offset, 239, 230, 49), func(): _close_pause())
	_button(t("return"), Rect2(365 + center_offset, 307, 230, 49), func(): camp_pressed.emit())
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

func _close_pause() -> void:
	get_tree().paused = false
	resume_pressed.emit()
	show_hunt(current_hunt)

func _clear() -> void:
	if root == null:
		return
	for action in ["move_left", "move_right", "jump", "dodge", "attack", "heavy", "special", "heal"]:
		Input.action_release(action)
	for child in root.get_children():
		if child.has_method("release_touch"):
			child.release_touch()
			child.set_process_input(false)
		child.queue_free()
	health_fill = null
	stamina_fill = null
	resource_fill = null
	resource_back = null
	resource_label = null
	boss_fill = null
	boss_group = null
	part_label = null
	target_label = null
	potion_label = null
	flash_label = null

func _right_offset() -> float:
	return layout_size.x - REFERENCE_SIZE.x

func _center_offset() -> float:
	return _right_offset() * 0.5

func _overlay(color: Color) -> void:
	var cover := ColorRect.new()
	cover.size = layout_size
	cover.color = color
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cover)

func _panel(box: Rect2, parent: Control = null) -> Panel:
	var panel := Panel.new()
	panel.position = box.position
	panel.size = box.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.105, 0.14, 0.91)
	style.border_color = Color("#9c7e52")
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	panel.add_theme_stylebox_override("panel", style)
	(parent if parent != null else root).add_child(panel)
	return panel

func _label(value: String, at: Vector2, size: Vector2, font_size: int, color: Color, parent: Control = null) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else root).add_child(label)
	return label

func _button(value: String, box: Rect2, on_press: Callable, parent: Control = null) -> Button:
	var button := Button.new()
	button.text = value
	button.position = box.position
	button.size = box.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#f8dfaa"))
	for state_name in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#3e5860") if state_name == "normal" else (Color("#62716a") if state_name == "hover" else (Color("#94714b") if state_name == "pressed" else Color("#35454a")))
		style.border_color = Color("#bd9b61")
		style.set_border_width_all(2)
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override(state_name, style)
	button.pressed.connect(on_press)
	(parent if parent != null else root).add_child(button)
	return button

func _bar(box: Rect2, color: Color) -> ColorRect:
	var bar := ColorRect.new()
	bar.position = box.position
	bar.size = box.size
	bar.color = color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	return bar

func _action_button(value: String, box: Rect2, action: String, primary: bool = false) -> void:
	var button := TouchActionButton.new()
	button.name = "Action_" + action
	button.position = box.position
	button.size = box.size
	button.caption = value
	button.action = action
	button.primary = primary
	root.add_child(button)
