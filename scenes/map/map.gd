extends TextureRect

const MAP_SIZE: Vector2i = Vector2i(200, 200)

const COLOR_WALL: Color = Color.WHITE
const COLOR_AIR: Color = Color.BLACK

const TERRAIN_FREQ: float = 0.01
const TERRAIN_THRESHOLD: float = -0.1

const SPAWN_DIAMETER: float = 30.0

var image: Image
var texture_ref: ImageTexture

var terrain_noise: FastNoiseLite = FastNoiseLite.new()
var base_seed: int = 0

var texture_dirty: bool = false

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	focus_mode = Control.FOCUS_CLICK
	
	image = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGBA8)
	texture_ref = ImageTexture.create_from_image(image)
	texture = texture_ref
	
	base_seed = randi()
	setup_noises()
	generate_world()

func _process(_delta: float) -> void:
	if texture_dirty:
		texture_ref.set_image(image)
		texture_dirty = false

func setup_noises() -> void:
	terrain_noise.seed = base_seed
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	terrain_noise.frequency = TERRAIN_FREQ
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = 3

func generate_world() -> void:
	for x in range(MAP_SIZE.x):
		for y in range(MAP_SIZE.y):
			var t_val: float = terrain_noise.get_noise_2d(x, y)
			if t_val > TERRAIN_THRESHOLD:
				image.set_pixel(x, y, COLOR_WALL)
			else:
				image.set_pixel(x, y, COLOR_AIR)
	
	var radius: float = SPAWN_DIAMETER / 2.0
	var radius_sq: float = radius * radius
	var center_x: float = float(MAP_SIZE.x) / 2.0
	var center_y: float = float(MAP_SIZE.y) / 2.0
	
	var blocked_centers: Array[Vector2] = [
		Vector2(center_x, 0),
		Vector2(center_x, MAP_SIZE.y - 1),
		Vector2(0, center_y),
		Vector2(MAP_SIZE.x - 1, center_y)
	]
	
	for center in blocked_centers:
		var start_x: int = int(clamp(center.x - radius, 0, MAP_SIZE.x))
		var end_x: int = int(clamp(center.x + radius, 0, MAP_SIZE.x))
		var start_y: int = int(clamp(center.y - radius, 0, MAP_SIZE.y))
		var end_y: int = int(clamp(center.y + radius, 0, MAP_SIZE.y))
		
		for x in range(start_x, end_x):
			for y in range(start_y, end_y):
				if Vector2(x, y).distance_squared_to(center) <= radius_sq:
					image.set_pixel(x, y, COLOR_AIR)

	texture_dirty = true

func is_walkable(map_pos: Vector2i) -> bool:
	if not is_valid_pos(map_pos):
		return false
	
	var pixel_color: Color = image.get_pixelv(map_pos)
	
	return pixel_color.is_equal_approx(COLOR_AIR)

func place_unit(map_pos: Vector2i, color: Color) -> void:
	if is_valid_pos(map_pos):
		image.set_pixelv(map_pos, color)
		texture_dirty = true

func clear_unit(map_pos: Vector2i) -> void:
	if is_valid_pos(map_pos):
		image.set_pixelv(map_pos, COLOR_AIR)
		texture_dirty = true

func move_unit_pixel(from_pos: Vector2i, to_pos: Vector2i, unit_color: Color) -> bool:
	if not is_walkable(to_pos):
		return false
		
	image.set_pixelv(from_pos, COLOR_AIR)
	image.set_pixelv(to_pos, unit_color)
	
	texture_dirty = true
	return true

func dig_at(local_pos: Vector2) -> void:
	var pixel_pos: Vector2i = Vector2i(local_pos.floor())
	if not is_valid_pos(pixel_pos): 
		return

	if image.get_pixelv(pixel_pos) == COLOR_WALL:
		image.set_pixelv(pixel_pos, COLOR_AIR)
		texture_dirty = true

func is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < MAP_SIZE.x and pos.y < MAP_SIZE.y
