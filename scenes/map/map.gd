class_name Map extends TextureRect

const MAP_SIZE: Vector2i = Vector2i(200, 200)
const SEED: int = 12345

const C_VOID = Color.BLACK
const C_WALL = Color(0.2, 0.2, 0.2)

const MIN_STRIP_HEIGHT = 20
const MIN_CELL_WIDTH = 20
const WALL_THICKNESS_BASE = 2
const WORM_CHAOS = 0.3

var image: Image
var texture_ref: ImageTexture
var rng: RandomNumberGenerator
var noise: FastNoiseLite
var cells_centers: Array[Vector2i] = []

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	image = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGBA8)
	texture_ref = ImageTexture.create_from_image(image)
	texture = texture_ref
	
	rng = RandomNumberGenerator.new()
	rng.seed = SEED
	
	noise = FastNoiseLite.new()
	noise.seed = SEED
	noise.frequency = 0.05
	noise.noise_type = FastNoiseLite.TYPE_PERLIN

	generate_world()
	apply_texture()

func regenerate(new_seed: int = -1) -> void:
	if new_seed == -1:
		rng.randomize() 
		var random_seed = rng.randi()
		rng.seed = random_seed
		noise.seed = random_seed
	else:
		rng.seed = new_seed
		noise.seed = new_seed
	
	generate_world()
	apply_texture()

func apply_texture() -> void:
	texture_ref.set_image(image)

func generate_world() -> void:
	image.fill(C_VOID)
	cells_centers.clear()
	
	generate_structure()
	run_worm()

func generate_structure() -> void:
	var current_y = 0
	
	while current_y < MAP_SIZE.y:
		var strip_h = rng.randi_range(MIN_STRIP_HEIGHT, MIN_STRIP_HEIGHT * 2)
		if current_y + strip_h > MAP_SIZE.y:
			strip_h = MAP_SIZE.y - current_y
		
		if current_y > 0:
			draw_organic_line(Vector2i(0, current_y), Vector2i(MAP_SIZE.x, current_y), true)

		var current_x = 0
		while current_x < MAP_SIZE.x:
			var cell_w = rng.randi_range(MIN_CELL_WIDTH, MIN_CELL_WIDTH * 2)
			if current_x + cell_w > MAP_SIZE.x:
				cell_w = MAP_SIZE.x - current_x
			
			if current_x > 0:
				draw_organic_line(Vector2i(current_x, current_y), Vector2i(current_x, current_y + strip_h), false)
			
			var center = Vector2i(current_x + cell_w / 2, current_y + strip_h / 2)
			center.x = clampi(center.x, 1, MAP_SIZE.x - 2)
			center.y = clampi(center.y, 1, MAP_SIZE.y - 2)
			cells_centers.append(center)
			
			current_x += cell_w
			
		current_y += strip_h

func draw_organic_line(start: Vector2i, end: Vector2i, horizontal: bool) -> void:
	var length = (end.x - start.x) if horizontal else (end.y - start.y)
	
	for i in range(length):
		var n_val = noise.get_noise_2d(start.x + i if horizontal else start.x, start.y + i if !horizontal else start.y)
		var offset = int(n_val * 4.0)
		var thickness = WALL_THICKNESS_BASE + int(abs(n_val) * 3.0)
		var px = start.x + i if horizontal else start.x + offset
		var py = start.y + offset if horizontal else start.y + i
		
		for t in range(-thickness/2, thickness/2 + 1):
			var final_x = px + (0 if horizontal else t)
			var final_y = py + (t if horizontal else 0)
			
			if final_x >= 0 and final_x < MAP_SIZE.x and final_y >= 0 and final_y < MAP_SIZE.y:
				image.set_pixel(final_x, final_y, C_WALL)

func run_worm() -> void:
	for i in range(cells_centers.size() - 1):
		var start = cells_centers[i]
		var target = cells_centers[i+1]
		carve_path(start, target)

func carve_path(from: Vector2i, to: Vector2i) -> void:
	var current = from
	image.set_pixel(current.x, current.y, C_VOID) 
	
	while current != to:
		var dir = Vector2i.ZERO
		var diff = to - current
		
		if abs(diff.x) > abs(diff.y):
			dir.x = sign(diff.x)
		else:
			dir.y = sign(diff.y)
			
		if rng.randf() < WORM_CHAOS:
			if rng.randf() > 0.5:
				dir = Vector2i(1 if rng.randf() > 0.5 else -1, 0)
			else:
				dir = Vector2i(0, 1 if rng.randf() > 0.5 else -1)
				
		current += dir
		
		current.x = clampi(current.x, 1, MAP_SIZE.x - 2)
		current.y = clampi(current.y, 1, MAP_SIZE.y - 2)
		
		drill_hole(current, 1)

func drill_hole(pos: Vector2i, radius: int) -> void:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var drill_pos = pos + Vector2i(x, y)
			if drill_pos.x >= 0 and drill_pos.x < MAP_SIZE.x and drill_pos.y >= 0 and drill_pos.y < MAP_SIZE.y:
				image.set_pixel(drill_pos.x, drill_pos.y, C_VOID)
