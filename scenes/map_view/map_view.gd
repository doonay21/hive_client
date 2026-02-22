class_name MapView extends Node2D

signal map_generated

enum MaterialType { VOID, SOFT_ROCK, HARD_ROCK, BEDROCK, GOLD, ROBOT }
enum RoomShape { CIRCLE, SQUARE, DIAMOND, CROSS, SUPERELLIPSE, CAVERN }

const MAP_SIZE: Vector2i = Vector2i(200, 200)
const TILE_SOURCE_ID: int = 0
const SPAWN_RADIUS: float = 12.0

const TILE_COORDS: Array[Vector2i] = [
	Vector2i.ZERO,  # 0: VOID
	Vector2i(1, 1), # 1: SOFT_ROCK
	Vector2i(3, 1), # 2: HARD_ROCK
	Vector2i(5, 1), # 3: BEDROCK
	Vector2i(1, 3), # 4: GOLD
	Vector2i(3, 3)  # 5: ROBOT
]

const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

@onready var tile_map: TileMapLayer = $TileMapLayer

var noise: FastNoiseLite
var room_pixels: Array[Vector2i] = []
var data_grid: PackedByteArray = []
var current_seed: int = 0
var map_bounds: Rect2i = Rect2i(Vector2i.ZERO, MAP_SIZE)

func _ready() -> void:
	randomize()
	
	noise = FastNoiseLite.new()
	noise.seed = current_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	noise.fractal_octaves = 2
	
	data_grid.resize(MAP_SIZE.x * MAP_SIZE.y)
	data_grid.fill(MaterialType.VOID)
	
	generate_world()

func clear_map(material_type: MaterialType = MaterialType.VOID) -> void:
	tile_map.clear()
	data_grid.fill(material_type)
	if material_type != MaterialType.VOID:
		for x in range(MAP_SIZE.x):
			for y in range(MAP_SIZE.y):
				set_tile(x, y, material_type)

func paint_at(map_pos: Vector2, brush_steps: int, material_type: MaterialType = MaterialType.VOID) -> void:
	var radius_sq: float = (brush_steps - 0.5) ** 2
	for x in range(-brush_steps, brush_steps + 1):
		for y in range(-brush_steps, brush_steps + 1):
			if (x * x + y * y) <= radius_sq:
				var target = Vector2i(int(map_pos.x + x), int(map_pos.y + y))
				if map_bounds.has_point(target):
					set_tile(target.x, target.y, material_type)

func get_material_at(pos: Vector2i) -> MaterialType:
	if not map_bounds.has_point(pos):
		return MaterialType.VOID
	
	return data_grid[pos.x + pos.y * MAP_SIZE.x] as MaterialType

func generate_world() -> void:
	tile_map.clear()
	current_seed = randi()
	noise.seed = current_seed
	room_pixels.clear()
	
	generate_noisy_background()
	
	var room_count_axis: int = 5
	@warning_ignore("integer_division")
	var room_w = MAP_SIZE.x / room_count_axis
	@warning_ignore("integer_division")
	var room_h = MAP_SIZE.y / room_count_axis
	@warning_ignore("integer_division")
	var center_index = room_count_axis / 2
	
	noise.frequency = 0.05 
	noise.fractal_octaves = 2
	
	for i in range(room_count_axis):
		for j in range(room_count_axis):
			var is_center_room = (i == center_index and j == center_index)
			var shape = RoomShape.CIRCLE if is_center_room else RoomShape.values().pick_random()
			
			create_noise_room(i * room_w, j * room_h, room_w, room_h, shape)
	
	create_random_edge_passages(room_count_axis, room_w, room_h)
	
	for n in range(60): 
		try_generate_gold_vein(true)
		
	for n in range(5):
		try_generate_gold_vein(false)
		
	add_complex_obstacles()
	create_spawn_point()
	
	encode_seed_in_tiles(current_seed)
	
	map_generated.emit()

func generate_noisy_background() -> void:
	noise.frequency = 0.08 
	noise.fractal_octaves = 4 
	
	var noise_img = noise.get_image(MAP_SIZE.x, MAP_SIZE.y)
	
	for x in range(MAP_SIZE.x):
		for y in range(MAP_SIZE.y):
			var pixel_val = noise_img.get_pixel(x, y).r
			
			if pixel_val < 0.45:
				set_tile(x, y, MaterialType.HARD_ROCK)
			elif pixel_val < 0.7:
				set_tile(x, y, MaterialType.SOFT_ROCK)
			elif pixel_val < 0.825:
				set_tile(x, y, MaterialType.HARD_ROCK)
			else:
				set_tile(x, y, MaterialType.BEDROCK)

func create_noise_room(ox: int, oy: int, w: int, h: int, shape_type: RoomShape) -> void:
	var center = Vector2(ox + w/2.0, oy + h/2.0)
	var margin = 4 
	var half_size = (min(w, h) / 2.0) - margin
	var cavern_noise_seed = randi()

	for x in range(ox + margin, ox + w - margin):
		for y in range(oy + margin, oy + h - margin):
			var dx = absf(x - center.x)
			var dy = absf(y - center.y)
			var nx = dx / half_size
			var ny = dy / half_size
			var dist_factor = 0.0
			var force_floor = false 
			
			match shape_type:
				RoomShape.CIRCLE:
					dist_factor = sqrt(dx * dx + dy * dy) / half_size
				RoomShape.SQUARE:
					dist_factor = max(dx, dy) / half_size
				RoomShape.DIAMOND:
					dist_factor = (dx + dy) / (half_size * 1.1) 
				RoomShape.CROSS:
					var thickness = 0.35
					var dist_vert = max(nx / thickness, ny)
					var dist_horiz = max(nx, ny / thickness)
					dist_factor = min(dist_vert, dist_horiz)
					
					if nx < 0.15 or ny < 0.15:
						force_floor = true
				RoomShape.SUPERELLIPSE:
					dist_factor = sqrt(sqrt(pow(nx, 4) + pow(ny, 4)))
				RoomShape.CAVERN:
					var base_dist = sqrt(nx*nx + ny*ny)
					var wobble = noise.get_noise_2d(x * 3.0 + cavern_noise_seed, y * 3.0)
					dist_factor = base_dist + (wobble * 0.4)

			var noise_val = noise.get_noise_2d(x, y)
			
			if dist_factor > 1.0:
				continue
			
			if force_floor:
				set_tile(x, y, MaterialType.SOFT_ROCK)
				room_pixels.append(Vector2i(x, y))
				continue
			
			if dist_factor > 0.70:
				if noise_val > -0.8: 
					set_tile(x, y, MaterialType.BEDROCK)
			else:
				var is_room_floor = false
				if dist_factor < 0.3 or noise_val <= 0.1:
					set_tile(x, y, MaterialType.SOFT_ROCK)
					is_room_floor = true
				else:
					set_tile(x, y, MaterialType.HARD_ROCK)
					is_room_floor = true
				
				if is_room_floor:
					room_pixels.append(Vector2i(x, y))

func try_generate_gold_vein(only_in_rooms: bool) -> void:
	var start_pos = Vector2i.ZERO
	var valid_start = false
	
	if only_in_rooms:
		if not room_pixels.is_empty():
			start_pos = room_pixels.pick_random()
			if get_material_at(start_pos) != MaterialType.BEDROCK:
				valid_start = true
	else:
		for attempt in range(20):
			var test_pos = Vector2i(randi() % MAP_SIZE.x, randi() % MAP_SIZE.y)
			if test_pos.x < 5 or test_pos.x > MAP_SIZE.x - 5 or test_pos.y < 5 or test_pos.y > MAP_SIZE.y - 5:
				continue
				
			var mat = get_material_at(test_pos)
			if mat == MaterialType.HARD_ROCK or mat == MaterialType.SOFT_ROCK:
				start_pos = test_pos
				valid_start = true
				break
	
	if not valid_start:
		return

	var curr = start_pos
	var length = randi_range(10, 30)
	var bounds = map_bounds.grow(-1) 
	
	for i in range(length):
		var current_mat = get_material_at(curr)
		
		if not (only_in_rooms and current_mat == MaterialType.BEDROCK):
			set_tile_v(curr, MaterialType.GOLD)
			
			if randf() > 0.7:
				var neighbor = curr + DIRS.pick_random()
				if bounds.has_point(neighbor):
					var n_mat = get_material_at(neighbor)
					if n_mat != MaterialType.BEDROCK and n_mat != MaterialType.GOLD:
						set_tile_v(neighbor, MaterialType.GOLD)
		
		var next_dir = Vector2i.ZERO
		
		if only_in_rooms:
			var safe_dirs: Array[Vector2i] = []
			for dir in DIRS:
				var check_pos = curr + dir
				if bounds.has_point(check_pos) and get_material_at(check_pos) != MaterialType.BEDROCK:
					safe_dirs.append(dir)
			
			if not safe_dirs.is_empty():
				next_dir = safe_dirs.pick_random()
			else:
				break 
		else:
			next_dir = DIRS.pick_random()

		curr += next_dir
		
		if not bounds.has_point(curr):
			break

func create_random_edge_passages(grid_size: int, rw: int, rh: int) -> void:
	var reach_w = int(rw * 0.3)
	var reach_h = int(rh * 0.3)
	
	for i in range(grid_size):
		for j in range(grid_size):
			if i < grid_size - 1:
				var edge_x = (i + 1) * rw
				var rand_y = (j * rh) + randi_range(int(rh * 0.3), int(rh * 0.7))
				dig_tunnel(Vector2i(edge_x - reach_w, rand_y), Vector2i(edge_x + reach_w, rand_y))

			if j < grid_size - 1:
				var edge_y = (j + 1) * rh
				var rand_x = (i * rw) + randi_range(int(rw * 0.3), int(rw * 0.7))
				dig_tunnel(Vector2i(rand_x, edge_y - reach_h), Vector2i(rand_x, edge_y + reach_h))

func dig_tunnel(from: Vector2i, to: Vector2i) -> void:
	var current = from
	var steps = int(from.distance_to(to)) * 2
	
	for s in range(steps):
		set_tile_v(current, MaterialType.SOFT_ROCK)
		if randf() > 0.3:
			set_tile(current.x + 1, current.y, MaterialType.SOFT_ROCK)
			set_tile(current.x, current.y + 1, MaterialType.SOFT_ROCK)

		var diff = to - current
		if diff == Vector2i.ZERO: break
		
		if abs(diff.x) > abs(diff.y):
			current.x += sign(diff.x)
			if randf() < 0.2: current.y += [1, -1].pick_random()
		else:
			current.y += sign(diff.y)
			if randf() < 0.2: current.x += [1, -1].pick_random()
			
		current.x = clampi(current.x, 1, MAP_SIZE.x - 2)
		current.y = clampi(current.y, 1, MAP_SIZE.y - 2)

func add_complex_obstacles() -> void:
	for i in range(100):
		generate_bedrock_artifact()

func generate_bedrock_artifact() -> void:
	var start = Vector2i.ZERO
	var valid = false
	
	for attempt in range(10):
		start = Vector2i(randi_range(5, MAP_SIZE.x - 6), randi_range(5, MAP_SIZE.y - 6))
		var current_mat = get_material_at(start)
		if current_mat == MaterialType.SOFT_ROCK or current_mat == MaterialType.HARD_ROCK:
			valid = true
			break
	
	if not valid: return

	match randi() % 4:
		0: build_ancient_ruin(start)
		1: build_pillar_cluster(start)
		2: build_dense_geode(start)
		3: build_hollow_box(start)

func build_ancient_ruin(pos: Vector2i) -> void:
	var walker = pos
	var steps = randi_range(15, 40)
	var direction = DIRS.pick_random()
	var bounds = map_bounds.grow(-2)
	
	for s in range(steps):
		set_tilev_safe(walker, MaterialType.BEDROCK)
		
		if randf() < 0.2:
			direction = [Vector2i.LEFT, Vector2i.RIGHT].pick_random() if direction.x == 0 else [Vector2i.UP, Vector2i.DOWN].pick_random()
		
		walker += direction * (2 if randf() > 0.85 else 1)
		
		if not bounds.has_point(walker):
			break

func build_pillar_cluster(pos: Vector2i) -> void:
	var radius = randi_range(3, 6)
	var radius_sq = radius * radius
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if (x*x + y*y) <= radius_sq:
				if (x + y) % 2 == 0 and randf() > 0.3:
					set_tilev_safe(pos + Vector2i(x, y), MaterialType.BEDROCK)

func build_dense_geode(pos: Vector2i) -> void:
	var walker = pos
	var mass = randi_range(10, 25)
	
	for i in range(mass):
		set_tilev_safe(walker, MaterialType.BEDROCK)
		walker += DIRS.pick_random()
		
		if walker.distance_squared_to(pos) > 25.0:
			walker = pos

func build_hollow_box(pos: Vector2i) -> void:
	var w = randi_range(4, 7)
	var h = randi_range(4, 7)
	
	for x in range(w):
		for y in range(h):
			var p = pos + Vector2i(x, y)

			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				if randf() > 0.1: 
					set_tilev_safe(p, MaterialType.BEDROCK)
			elif randf() > 0.5:
				set_tilev_safe(p, MaterialType.VOID)

func set_tile(x: int, y: int, material_type: MaterialType) -> void:
	data_grid[x + y * MAP_SIZE.x] = material_type
	
	var pos = Vector2i(x, y)
	if material_type == MaterialType.VOID:
		tile_map.erase_cell(pos)
	else:
		tile_map.set_cell(pos, TILE_SOURCE_ID, TILE_COORDS[material_type])

func set_tile_v(pos: Vector2i, material_type: MaterialType) -> void:
	set_tile(pos.x, pos.y, material_type)

func set_tile_safe(x: int, y: int, material_type: MaterialType) -> void:
	var pos = Vector2i(x, y)
	if map_bounds.has_point(pos):
		var current = get_material_at(pos)
		if current == MaterialType.SOFT_ROCK or current == MaterialType.HARD_ROCK:
			set_tile(x, y, material_type)

func set_tilev_safe(pos: Vector2i, material_type: MaterialType) -> void:
	set_tile_safe(pos.x, pos.y, material_type)

func create_spawn_point() -> void:
	var center = Vector2(MAP_SIZE.x / 2.0, MAP_SIZE.y / 2.0)
	var radius_sq = SPAWN_RADIUS * SPAWN_RADIUS
	
	var start_x = int(center.x - SPAWN_RADIUS)
	var end_x = int(center.x + SPAWN_RADIUS)
	var start_y = int(center.y - SPAWN_RADIUS)
	var end_y = int(center.y + SPAWN_RADIUS)

	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			if map_bounds.has_point(Vector2i(x,y)):
				var dx = x - center.x
				var dy = y - center.y
				if dx * dx + dy * dy <= radius_sq:
					set_tile(x, y, MaterialType.VOID)

func encode_seed_in_tiles(seed_val: int) -> void:
	var y = MAP_SIZE.y - 1
	
	for x in range(64):
		set_tile(x, y, MaterialType.VOID)
	
	for i in range(64):
		if (seed_val & (1 << i)) != 0:
			set_tile(i, y, MaterialType.BEDROCK)
	
	for x in range(4):
		set_tile(64 + x, y, MaterialType.SOFT_ROCK)

func extract_seed_from_tiles() -> int:
	var recovered_seed: int = 0
	var y = MAP_SIZE.y - 1
	
	for i in range(64):
		var mat = get_material_at(Vector2i(i, y))
		
		if mat == MaterialType.BEDROCK:
			recovered_seed |= (1 << i)
			
	return recovered_seed

func get_random_empty_spawn_point() -> Vector2i:
	var center: Vector2 = Vector2(MAP_SIZE) / 2.0
	var radius_sq: float = SPAWN_RADIUS * SPAWN_RADIUS
	var max_attempts: int = 100
	
	var start_x: int = int(center.x - SPAWN_RADIUS)
	var end_x: int = int(center.x + SPAWN_RADIUS)
	var start_y: int = int(center.y - SPAWN_RADIUS)
	var end_y: int = int(center.y + SPAWN_RADIUS)

	for i in range(max_attempts):
		var x: int = randi_range(start_x, end_x)
		var y: int = randi_range(start_y, end_y)
		var dx: float = x - center.x
		var dy: float = y - center.y
		
		if dx * dx + dy * dy <= radius_sq:
			var pos: Vector2i = Vector2i(x, y)
			
			if map_bounds.has_point(pos) and get_material_at(pos) == MaterialType.VOID:
				return pos
				
	return Vector2i(-1, -1)
