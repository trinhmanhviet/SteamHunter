extends RefCounted

const Hurtbox = preload("res://scripts/sprite_hurtbox.gd")

static func polygon(outline: PackedVector2Array, origin: Vector2, angle: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in outline: result.append(origin + point.rotated(angle))
	return result

static func between(outline: PackedVector2Array, a: Vector2, angle_a: float,
	b: Vector2, angle_b: float) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var count := maxi(1, maxi(int(ceil(absf(angle_b - angle_a) / deg_to_rad(2))),
		int(ceil(a.distance_to(b) / 2.0))))
	var previous := polygon(outline, a, angle_a)
	for i in range(1, count + 1):
		var t := float(i) / count
		var current := polygon(outline, a.lerp(b, t), lerpf(angle_a, angle_b, t))
		var points := previous + current
		result.append(Geometry2D.convex_hull(points))
		previous = current
	return result

static func overlaps(pieces: Array[PackedVector2Array], target: Array[PackedVector2Array]) -> bool:
	var target_bounds: Array[Rect2] = []
	for shape in target: target_bounds.append(Hurtbox.bounds(shape))
	for piece in pieces:
		var bounds := Hurtbox.bounds(piece)
		for i in target.size():
			if bounds.intersects(target_bounds[i]) and not Geometry2D.intersect_polygons(piece, target[i]).is_empty():
				return true
	return false

static func overlaps_sprite(pieces: Array[PackedVector2Array], sprite: Sprite2D) -> bool:
	if pieces.is_empty() or sprite == null: return false
	var rect := sprite.get_rect()
	var quad := PackedVector2Array([sprite.to_global(rect.position),
		sprite.to_global(Vector2(rect.end.x,rect.position.y)), sprite.to_global(rect.end),
		sprite.to_global(Vector2(rect.position.x,rect.end.y))])
	var target_bounds := Hurtbox.bounds(quad)
	var close := false
	for piece in pieces:
		if Hurtbox.bounds(piece).intersects(target_bounds):
			close = true
			break
	if not close: return false
	return overlaps(pieces, Hurtbox.world_polygons(sprite))
