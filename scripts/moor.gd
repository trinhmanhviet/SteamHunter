extends Node2D

const WORLD_WIDTH := 3000.0
const GROUND_Y := 468.0
var biome := "moor"

func _ready() -> void:
	for i in range(4):
		var back := Sprite2D.new()
		back.texture = load("res://art/briarwood_back.png") if biome == "briarwood" else load("res://art/moor_back.png")
		back.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if biome == "briarwood":
			back.scale = Vector2(960.0 / back.texture.get_width(), 540.0 / back.texture.get_height())
		back.position = Vector2(480 + i * 960, 270)
		back.flip_h = i % 2 == 1
		back.z_index = -10
		add_child(back)
	_add_floor()
	var platforms := [Vector2(635, 364), Vector2(1170, 302), Vector2(1680, 370), Vector2(2130, 328), Vector2(2745, 340)]
	if biome == "briarwood":
		platforms = [Vector2(580, 344), Vector2(1050, 375), Vector2(1510, 309), Vector2(2050, 362), Vector2(2685, 335)]
	for at in platforms:
		_add_platform(at)

func _add_floor() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(WORLD_WIDTH / 2.0, GROUND_Y + 44.0)
	var floor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WORLD_WIDTH, 88)
	floor_shape.shape = rect
	floor_body.add_child(floor_shape)
	add_child(floor_body)
	var left_wall := StaticBody2D.new()
	left_wall.position = Vector2(-14, 270)
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(28, 540)
	wall_shape.shape = wall_rect
	left_wall.add_child(wall_shape)
	add_child(left_wall)

func _add_platform(at: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at + Vector2(0, 16)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(304, 22)
	shape.shape = rect
	body.add_child(shape)
	var art := Sprite2D.new()
	art.texture = load("res://art/forest_platform.png") if biome == "briarwood" else load("res://art/platform.png")
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if biome == "briarwood":
		art.scale = Vector2(330.0 / art.texture.get_width(), 72.0 / art.texture.get_height())
	art.position = Vector2(0, 12)
	body.add_child(art)
	add_child(body)
