class_name Map extends TextureRect

enum MaterialType { VOID, SOFT_ROCK, HARD_ROCK, BEDROCK, GOLD, ROBOT }
enum RoomShape { CIRCLE, SQUARE, DIAMOND, CROSS, SUPERELLIPSE, CAVERN }

const MAP_SIZE: Vector2i = Vector2i(200, 200)

const COLORS: PackedColorArray = [
	Color("000000"),       # VOID = 0
	Color("A89F83"),       # SOFT_ROCK = 1
	Color("696969"),       # HARD_ROCK = 2
	Color("1A1A1A"),       # BEDROCK = 3
	Color("FFC30B"),       # GOLD = 4
	Color("ff0000")        # ROBOT = 6
]

var image: Image
var texture_ref: ImageTexture
var texture_dirty: bool = false
var noise: FastNoiseLite

var room_pixels: Array[Vector2i] = []
var data_grid: PackedByteArray = []
var current_seed: int = 0

var robots: Array[Robot] = []

func _ready() -> void:
	randomize()
	
	noise = FastNoiseLite.new()
	noise.seed = current_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	noise.fractal_octaves = 2

	texture_filter = TEXTURE_FILTER_NEAREST
	focus_mode = Control.FOCUS_CLICK
	
	image = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGBA8)
	texture_ref = ImageTexture.create_from_image(image)
	texture = texture_ref
	
	data_grid.resize(MAP_SIZE.x * MAP_SIZE.y)
	
	generate_world()

func _process(_delta: float) -> void:
	if texture_dirty:
		texture_ref.update(image)
		texture_dirty = false

func update() -> void:
	for robot in robots:
		pass

func add_robot(robot: Robot) -> void:
	robots.append(robot)

func clear_map(material_type: MaterialType = MaterialType.VOID) -> void:
	image.fill(COLORS[material_type])
	texture_dirty = true

func paint_at(img_pos: Vector2, brush_steps: int, material_type: MaterialType = MaterialType.VOID) -> void:
	for x in range(-brush_steps, brush_steps + 1):
		for y in range(-brush_steps, brush_steps + 1):
			if Vector2(x, y).length() <= brush_steps - 0.5:
				var target_x = int(img_pos.x + x)
				var target_y = int(img_pos.y + y)
				
				if target_x >= 0 and target_x < MAP_SIZE.x and target_y >= 0 and target_y < MAP_SIZE.y:
					set_pixel(target_x, target_y, material_type)
	
	texture_dirty = true

func get_material_at(pos: Vector2i) -> MaterialType:
	if pos.x < 0 or pos.x >= MAP_SIZE.x or pos.y < 0 or pos.y >= MAP_SIZE.y:
		return MaterialType.BEDROCK
	return data_grid[pos.x + pos.y * MAP_SIZE.x] as MaterialType

func generate_world() -> void:
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
			var shape = RoomShape.values().pick_random()
			
			if is_center_room:
				shape = RoomShape.CIRCLE
			
			create_noise_room(i * room_w, j * room_h, room_w, room_h, shape)
	
	create_random_edge_passages(room_count_axis, room_w, room_h)
	
	for n in range(60): 
		try_generate_gold_vein(true)
		
	for n in range(5):
		try_generate_gold_vein(false)
		
	add_complex_obstacles()
	create_spawn_point(12.0)
	
	encode_seed_in_pixels(current_seed)
	
	texture_dirty = true

func generate_noisy_background() -> void:
	noise.frequency = 0.08 
	noise.fractal_octaves = 4 
	
	var noise_img = noise.get_image(MAP_SIZE.x, MAP_SIZE.y)
	
	for x in range(MAP_SIZE.x):
		for y in range(MAP_SIZE.y):
			var pixel_val = noise_img.get_pixel(x, y).r
			
			if pixel_val < 0.45:
				set_pixel(x, y, MaterialType.HARD_ROCK)
			elif pixel_val < 0.7:
				set_pixel(x, y, MaterialType.SOFT_ROCK)
			elif pixel_val < 0.825:
				set_pixel(x, y, MaterialType.HARD_ROCK)
			else:
				set_pixel(x, y, MaterialType.BEDROCK)

func create_noise_room(ox: int, oy: int, w: int, h: int, shape_type: RoomShape) -> void:
	var center = Vector2(ox + w/2.0, oy + h/2.0)
	var margin = 4 
	var half_size = (min(w, h) / 2.0) - margin
	var cavern_noise_seed = randi()

	for x in range(ox + margin, ox + w - margin):
		for y in range(oy + margin, oy + h - margin):
			var dist_factor = 0.0
			var dx = abs(x - center.x)
			var dy = abs(y - center.y)
			var nx = dx / half_size
			var ny = dy / half_size
			var force_floor = false 
			
			match shape_type:
				RoomShape.CIRCLE:
					var dist = Vector2(x, y).distance_to(center)
					dist_factor = dist / half_size
				RoomShape.SQUARE:
					var max_axis = max(dx, dy)
					dist_factor = max_axis / half_size
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
				set_pixel(x, y, MaterialType.SOFT_ROCK)
				room_pixels.append(Vector2i(x, y))
				continue
			
			if dist_factor > 0.70:
				if noise_val > -0.8: 
					set_pixel(x, y, MaterialType.BEDROCK)
			else:
				var is_room_floor = false
				if dist_factor < 0.3:
					set_pixel(x, y, MaterialType.SOFT_ROCK)
					is_room_floor = true
				elif noise_val > 0.1:
					set_pixel(x, y, MaterialType.HARD_ROCK)
					is_room_floor = true
				else:
					set_pixel(x, y, MaterialType.SOFT_ROCK)
					is_room_floor = true
				
				if is_room_floor:
					room_pixels.append(Vector2i(x, y))

func try_generate_gold_vein(only_in_rooms: bool) -> void:
	var start_pos = Vector2i.ZERO
	var valid_start = false
	
	if only_in_rooms:
		if room_pixels.size() > 0:
			start_pos = room_pixels.pick_random()
			if image.get_pixelv(start_pos) != COLORS[MaterialType.BEDROCK]:
				valid_start = true
	else:
		for attempt in range(20):
			var test_pos = Vector2i(randi() % MAP_SIZE.x, randi() % MAP_SIZE.y)
			if test_pos.x < 5 or test_pos.x > MAP_SIZE.x - 5 or test_pos.y < 5 or test_pos.y > MAP_SIZE.y - 5:
				continue
				
			var pixel = image.get_pixelv(test_pos)
			if pixel == COLORS[MaterialType.HARD_ROCK] or pixel == COLORS[MaterialType.SOFT_ROCK]:
				start_pos = test_pos
				valid_start = true
				break
	
	if not valid_start:
		return

	var curr = start_pos
	var length = randi_range(10, 30)
	var bounds = Rect2i(1, 1, MAP_SIZE.x - 2, MAP_SIZE.y - 2)
	
	for i in range(length):
		var current_pixel = image.get_pixelv(curr)
		
		if only_in_rooms and current_pixel == COLORS[MaterialType.BEDROCK]:
			pass
		else:
			set_pixel_v(curr, MaterialType.GOLD)
			
			if randf() > 0.7:
				var neighbor = curr + [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
				if bounds.has_point(neighbor):
					var n_pixel = image.get_pixelv(neighbor)
					if n_pixel != COLORS[MaterialType.BEDROCK] and n_pixel != COLORS[MaterialType.GOLD]:
						set_pixel_v(neighbor, MaterialType.GOLD)
		
		var possible_dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		var next_dir = Vector2i.ZERO
		
		if only_in_rooms:
			var safe_dirs = []
			for dir in possible_dirs:
				var check_pos = curr + dir
				if bounds.has_point(check_pos) and image.get_pixelv(check_pos) != COLORS[MaterialType.BEDROCK]:
					safe_dirs.append(dir)
			
			if safe_dirs.size() > 0:
				next_dir = safe_dirs.pick_random()
			else:
				break 
		else:
			next_dir = possible_dirs.pick_random()

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
				@warning_ignore("narrowing_conversion")
				var rand_y = (j * rh) + randi_range(rh * 0.3, rh * 0.7)
				dig_tunnel(Vector2i(edge_x - reach_w, rand_y), Vector2i(edge_x + reach_w, rand_y))

			if j < grid_size - 1:
				var edge_y = (j + 1) * rh
				@warning_ignore("narrowing_conversion")
				var rand_x = (i * rw) + randi_range(rw * 0.3, rw * 0.7)
				dig_tunnel(Vector2i(rand_x, edge_y - reach_h), Vector2i(rand_x, edge_y + reach_h))

func dig_tunnel(from: Vector2i, to: Vector2i) -> void:
	var current = from
	var steps = int(from.distance_to(to)) * 2
	
	for s in range(steps):
		set_pixel_v(current, MaterialType.SOFT_ROCK)
		if randf() > 0.3:
			set_pixel(current.x + 1, current.y, MaterialType.SOFT_ROCK)
			set_pixel(current.x, current.y + 1, MaterialType.SOFT_ROCK)

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

	var type = randi() % 4
	
	match type:
		0: build_ancient_ruin(start)
		1: build_pillar_cluster(start)
		2: build_dense_geode(start)
		3: build_hollow_box(start)

func build_ancient_ruin(pos: Vector2i) -> void:
	var walker = pos
	var steps = randi_range(15, 40)
	var direction = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
	
	for s in range(steps):
		set_pixelv_safe(walker, MaterialType.BEDROCK)
		
		if randf() < 0.2:
			if direction.x == 0:
				direction = [Vector2i.LEFT, Vector2i.RIGHT].pick_random()
			else:
				direction = [Vector2i.UP, Vector2i.DOWN].pick_random()
		
		if randf() > 0.85:
			walker += direction
		
		walker += direction
		
		if walker.x < 2 or walker.x >= MAP_SIZE.x - 2 or walker.y < 2 or walker.y >= MAP_SIZE.y - 2:
			break

func build_pillar_cluster(pos: Vector2i) -> void:
	var radius = randi_range(3, 6)
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if Vector2(x, y).length() <= radius:
				if (x + y) % 2 == 0 and randf() > 0.3:
					set_pixelv_safe(pos + Vector2i(x, y), MaterialType.BEDROCK)

func build_dense_geode(pos: Vector2i) -> void:
	var walker = pos
	var mass = randi_range(10, 25)
	
	for i in range(mass):
		set_pixelv_safe(walker, MaterialType.BEDROCK)
		walker += [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
		
		if walker.distance_to(pos) > 5.0:
			walker = pos

func build_hollow_box(pos: Vector2i) -> void:
	var w = randi_range(4, 7)
	var h = randi_range(4, 7)
	
	for x in range(w):
		for y in range(h):
			var p = pos + Vector2i(x, y)

			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				if randf() > 0.1: 
					set_pixelv_safe(p, MaterialType.BEDROCK)
			else:
				if randf() > 0.5:
					set_pixelv_safe(p, MaterialType.VOID)

func set_pixel(x: int, y: int, material_type: MaterialType) -> void:
	image.set_pixel(x, y, COLORS[material_type])
	data_grid[x + y * MAP_SIZE.x] = material_type

func set_pixel_v(pos: Vector2i, material_type: MaterialType) -> void:
	set_pixel(pos.x, pos.y, material_type)

func set_pixel_safe(x: int, y: int, material_type: MaterialType) -> void:
	if x >= 0 and x < MAP_SIZE.x and y >= 0 and y < MAP_SIZE.y:
		var current = image.get_pixel(x, y)
		if current == COLORS[MaterialType.SOFT_ROCK] or current == COLORS[MaterialType.HARD_ROCK]:
			set_pixel(x, y, material_type)

func set_pixelv_safe(pos: Vector2i, material_type: MaterialType) -> void:
	set_pixel_safe(pos.x, pos.y, material_type)

func create_spawn_point(radius: float) -> void:
	var center = Vector2(MAP_SIZE.x / 2.0, MAP_SIZE.y / 2.0)
	
	var start_x = int(center.x - radius)
	var end_x = int(center.x + radius)
	var start_y = int(center.y - radius)
	var end_y = int(center.y + radius)

	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			if x < 0 or x >= MAP_SIZE.x or y < 0 or y >= MAP_SIZE.y:
				continue
			
			if Vector2(x, y).distance_to(center) <= radius:
				set_pixel(x, y, MaterialType.VOID)

func encode_seed_in_pixels(seed_val: int) -> void:
	var y = MAP_SIZE.y - 1
	
	for x in range(64):
		set_pixel(x, y, MaterialType.HARD_ROCK)
	
	for i in range(64):
		if (seed_val & (1 << i)) != 0:
			set_pixel(i, y, MaterialType.BEDROCK)

func extract_seed_from_pixels() -> int:
	var recovered_seed: int = 0
	var y = MAP_SIZE.y - 1
	
	for i in range(64):
		var mat = get_material_at(Vector2i(i, y))
		
		if mat == MaterialType.BEDROCK:
			recovered_seed |= (1 << i)
			
	return recovered_seed
