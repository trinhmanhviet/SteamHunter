extends SceneTree

const Hurtbox = preload("res://scripts/sprite_hurtbox.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func box(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x,y), Vector2(x+w,y), Vector2(x+w,y+h), Vector2(x,y+h)])

func _initialize() -> void:
	var image := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	# Asymmetric, disconnected opaque patches with a large transparent gap.
	for y in range(4, 8):
		for x in range(2, 6): image.set_pixel(x, y, Color.WHITE)
	for y in range(12, 16):
		for x in range(14, 18): image.set_pixel(x, y, Color.WHITE)
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = false
	root.add_child(sprite)
	check(Hurtbox.overlaps(box(3,5,1,1), sprite), "blade inside visible body hits")
	check(not Hurtbox.overlaps(box(8,8,3,3), sprite), "transparent interior gap must miss")
	check(not Hurtbox.overlaps(box(21,4,2,2), sprite), "nearby blade outside the image misses")
	sprite.scale = Vector2(2, 2)
	sprite.position = Vector2(50, 30)
	check(Hurtbox.overlaps(box(56,40,1,1), sprite), "hurt silhouette follows scale and position")
	sprite.flip_h = true
	check(not Hurtbox.overlaps(box(56,40,1,1), sprite), "old location becomes empty after mirroring")
	check(Hurtbox.overlaps(box(80,40,1,1), sprite), "mirrored opaque patch collides")
	sprite.position = Vector2.ZERO
	sprite.scale = Vector2.ONE
	sprite.flip_h = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(10,10,10,10)
	check(Hurtbox.overlaps(box(5,3,1,1), sprite), "atlas-region silhouette uses only the selected cell")
	check(not Hurtbox.overlaps(box(2,7,1,1), sprite), "another atlas cell cannot leak into the hurtbox")
	var ring := Image.create(20,20,false,Image.FORMAT_RGBA8)
	ring.fill(Color.WHITE)
	for y in range(3,17):
		for x in range(3,17): ring.set_pixel(x,y,Color.TRANSPARENT)
	sprite.texture = ImageTexture.create_from_image(ring)
	sprite.region_enabled = false
	check(not Hurtbox.overlaps(box(7,7,2,2), sprite), "closed silhouette holes remain non-damaging empty space")
	sprite.free()
	print("SPRITE_HURTBOX: 9 checks, %d failures" % failures)
	quit(1 if failures else 0)
