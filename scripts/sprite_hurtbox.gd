extends RefCounted

static var _rectangles: Dictionary = {}

static func local_rectangles(texture: Texture2D, region := Rect2()) -> Array[Rect2]:
	var source := texture.resource_path if not texture.resource_path.is_empty() else str(texture.get_rid().get_id())
	var key := source + ":" + str(region)
	if _rectangles.has(key):
		return _rectangles[key]
	var image := texture.get_image()
	if image.is_compressed(): image.decompress()
	if region.has_area(): image = image.get_region(Rect2i(region))
	var result: Array[Rect2] = []
	var active: Dictionary = {}
	for y in image.get_height():
		var spans: Dictionary = {}
		var x := 0
		while x < image.get_width():
			if image.get_pixel(x, y).a < .5:
				x += 1
				continue
			var start := x
			while x < image.get_width() and image.get_pixel(x, y).a >= .5:
				x += 1
			var span := Vector2i(start, x)
			spans[span] = true
			if active.has(span):
				var rect: Rect2 = active[span]
				rect.size.y += 1
				active[span] = rect
			else:
				active[span] = Rect2(start, y, x - start, 1)
		for span in active.keys():
			if not spans.has(span):
				result.append(active[span])
				active.erase(span)
	for rect in active.values(): result.append(rect)
	_rectangles[key] = result
	return result

static func world_polygons(sprite: Sprite2D) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if sprite == null or sprite.texture == null: return result
	var draw_origin := sprite.get_rect().position
	var size := sprite.region_rect.size if sprite.region_enabled else sprite.texture.get_size()
	var region := sprite.region_rect if sprite.region_enabled else Rect2()
	for rect in local_rectangles(sprite.texture, region):
		var polygon := PackedVector2Array()
		for pixel in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
			Vector2(rect.position.x, rect.end.y)]:
			var point: Vector2 = pixel
			if sprite.flip_h: point.x = size.x - point.x
			if sprite.flip_v: point.y = size.y - point.y
			polygon.append(sprite.to_global(point + draw_origin))
		result.append(polygon)
	return result

static func bounds(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty(): return Rect2()
	var rect := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon: rect = rect.expand(point)
	return rect

static func overlaps(blade: PackedVector2Array, sprite: Sprite2D) -> bool:
	if blade.size() < 3 or sprite == null: return false
	var blade_bounds := bounds(blade)
	for polygon in world_polygons(sprite):
		if blade_bounds.intersects(bounds(polygon)) and not Geometry2D.intersect_polygons(blade, polygon).is_empty():
			return true
	return false
