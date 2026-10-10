extends RefCounted

const BODY := "res://art/characters/hunter/body_atlas.png"
const WEAPON := "res://art/weapons/great_cleaver/overhead_atlas.png"
const FRAMES := "res://art/characters/hunter/overhead_frames.json"
const BODY_PIVOT := Vector2(64, 116)
const WEAPON_PIVOT := Vector2(192, 244)
const CONTACT_TIME := 1.0 / 30.0
const SETTLE_TIME := .22
const RECOVER_TIME := .48
const POST_HIT_TIME := CONTACT_TIME + SETTLE_TIME + RECOVER_TIME
static var _frames: Dictionary = {}

static func metadata() -> Dictionary:
	if _frames.is_empty():
		_frames = JSON.parse_string(FileAccess.get_file_as_string(FRAMES))
	return _frames

static func stage_frame(stage: String, progress: float) -> int:
	var indices: Array = metadata().stages[stage]
	# The same phase time must select the same cell despite subtraction roundoff.
	return int(indices[clampi(int(progress * indices.size() + .000001), 0, indices.size() - 1)])

static func frame_for(charge: float, elapsed: float, action: Dictionary, from_hold: bool) -> int:
	if charge > 0.0:
		if charge < .20:
			return stage_frame("raise", charge / .20)
		return stage_frame("hold", fmod(charge - .20, .40) / .40)
	if action.is_empty():
		return 0
	if int(action.get("damage", 0)) == 0:
		return stage_frame("hold", .0)
	var hit: float = action.hit_at
	if elapsed < hit:
		var wind_end := maxf(0.0, hit - 2.0 / 30.0)
		if from_hold and elapsed < wind_end:
			return stage_frame("hold", 0.0)
		if elapsed < wind_end:
			return stage_frame("raise", elapsed / maxf(wind_end, .00001))
		# The third downswing frame is contact, reserved for the hit event itself.
		var strike: Array = metadata().stages.strike
		var progress := (elapsed - wind_end) / maxf(hit - wind_end, .00001)
		return int(strike[clampi(int(progress * 2), 0, 1)])
	var after_hit := elapsed - hit
	if after_hit < 1.0 / 30.0:
		return int(metadata().stages.strike[-1])
	var since_contact := after_hit - CONTACT_TIME
	if since_contact < SETTLE_TIME:
		return stage_frame("settle", since_contact / SETTLE_TIME)
	return stage_frame("recover", (since_contact - SETTLE_TIME) / RECOVER_TIME)

static func region(index: int, layer: String) -> Rect2:
	var coords: Array = metadata().frames[index][layer]
	return Rect2(coords[0], coords[1], coords[2], coords[3])

static func blade_outline() -> PackedVector2Array:
	var outline := PackedVector2Array()
	for point in metadata().blade_local: outline.append(Vector2(point[0], point[1]))
	return outline

static func blade_pose(elapsed: float, action: Dictionary) -> Dictionary:
	var hit: float = action.hit_at
	var start := maxf(0, hit - 2.0 / 30.0)
	var progress := clampf((elapsed - start) / maxf(.00001, hit - start), 0, 1) * 2
	# Match the currently displayed downswing cell. Sweep only between displayed
	# poses, never advance the damaging sword ahead of the visible animation.
	var index := mini(2, int(progress))
	var stages: Array = metadata().stages.strike
	var a: Dictionary = metadata().frames[int(stages[index])]
	return {"origin": Vector2(a.weapon_origin[0], a.weapon_origin[1]), "angle": a.weapon_angle}
