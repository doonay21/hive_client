class_name Map extends TextureRect

const MAP_SIZE: Vector2i = Vector2i(200, 200)

const BEDROCK = Color(0.1, 0.1, 0.1)
const HARD_ROCK = Color(0.3, 0.3, 0.3)
const SOFT_ROCK = Color(0.6, 0.6, 0.6)
const GOLD = Color(1.0, 0.84, 0.0)

var image: Image
var texture_ref: ImageTexture
var texture_dirty: bool = false
var noise: FastNoiseLite

func _ready() -> void:
	randomize()
	
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	noise.fractal_octaves = 2

	texture_filter = TEXTURE_FILTER_NEAREST
	focus_mode = Control.FOCUS_CLICK
	
	image = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGBA8)
	texture_ref = ImageTexture.create_from_image(image)
	texture = texture_ref
	
	generate_world()

func _process(_delta: float) -> void:
	if texture_dirty:
		texture_ref.update(image)
		texture_dirty = false

func generate_world() -> void:
	noise.seed = randi()
	
	image.fill(BEDROCK)
	
	var room_count_axis = 5
	var room_w = MAP_SIZE.x / room_count_axis
	var room_h = MAP_SIZE.y / room_count_axis
	
	for i in range(room_count_axis):
		for j in range(room_count_axis):
			_create_noise_room(i * room_w, j * room_h, room_w, room_h)
			
	_create_random_edge_passages(room_count_axis, room_w, room_h)
	
	for n in range(40): 
		_generate_gold_vein()
		
	_add_complex_obstacles()
	
	texture_dirty = true

func _create_noise_room(ox: int, oy: int, w: int, h: int) -> void:
	var center = Vector2(ox + w/2.0, oy + h/2.0)
	var margin = 4 
	
	for x in range(ox + margin, ox + w - margin):
		for y in range(oy + margin, oy + h - margin):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var max_dist = (min(w, h) / 2.0) - margin
			
			var dist_factor = dist / max_dist
			var noise_val = noise.get_noise_2d(x, y)
			
			if dist_factor > 1.0:
				continue
				
			if dist_factor < 0.3:
				image.set_pixel(x, y, SOFT_ROCK)
			elif noise_val > 0.1:
				image.set_pixel(x, y, HARD_ROCK)
			else:
				image.set_pixel(x, y, SOFT_ROCK)

func _create_random_edge_passages(grid_size: int, rw: int, rh: int) -> void:
	var reach_w = int(rw * 0.3)
	var reach_h = int(rh * 0.3)
	
	for i in range(grid_size):
		for j in range(grid_size):
			if i < grid_size - 1:
				var edge_x = (i + 1) * rw
				var rand_y = (j * rh) + randi_range(rh * 0.3, rh * 0.7)
				_dig_tunnel(Vector2i(edge_x - reach_w, rand_y), Vector2i(edge_x + reach_w, rand_y))

			if j < grid_size - 1:
				var edge_y = (j + 1) * rh
				var rand_x = (i * rw) + randi_range(rw * 0.3, rw * 0.7)
				_dig_tunnel(Vector2i(rand_x, edge_y - reach_h), Vector2i(rand_x, edge_y + reach_h))

func _dig_tunnel(from: Vector2i, to: Vector2i) -> void:
	var current = from
	var steps = int(from.distance_to(to)) * 2
	
	for s in range(steps):
		image.set_pixelv(current, SOFT_ROCK)
		if randf() > 0.3:
			image.set_pixel(current.x + 1, current.y, SOFT_ROCK)
			image.set_pixel(current.x, current.y + 1, SOFT_ROCK)

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

func _generate_gold_vein() -> void:
	var curr = Vector2i(randi() % MAP_SIZE.x, randi() % MAP_SIZE.y)
	var length = randi_range(15, 45)
	
	for i in range(length):
		if curr.x > 0 and curr.x < MAP_SIZE.x - 1 and curr.y > 0 and curr.y < MAP_SIZE.y - 1:
			var pixel = image.get_pixelv(curr)
			if pixel != BEDROCK or randf() < 0.05: 
				image.set_pixelv(curr, GOLD)
				
				if randf() > 0.6:
					var neighbor = curr + [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
					image.set_pixelv(neighbor, GOLD)
		
		var dir = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
		curr += dir

func _add_complex_obstacles() -> void:
	for i in range(50):
		var start = Vector2i(randi() % (MAP_SIZE.x - 10) + 5, randi() % (MAP_SIZE.y - 10) + 5)
		
		if image.get_pixelv(start) == BEDROCK:
			continue
			
		var type = randi() % 3
		
		match type:
			0:
				var length = randi_range(4, 12)
				var dir = Vector2i(1, 0) if randf() > 0.5 else Vector2i(0, 1)
				for k in range(length):
					set_pixelv_safe(start + (dir * k), BEDROCK)
					
			1:
				var len_a = randi_range(4, 10)
				var len_b = randi_range(4, 10)
				for k in range(len_a):
					set_pixelv_safe(start + Vector2i(k, 0), BEDROCK)
				var corner = start + Vector2i(len_a - 1, 0)
				var dir_b = Vector2i(0, 1) if randf() > 0.5 else Vector2i(0, -1)
				for k in range(len_b):
					set_pixelv_safe(corner + (dir_b * k), BEDROCK)
			
			2:
				set_pixelv_safe(start, BEDROCK)
				set_pixelv_safe(start + Vector2i(1,0), BEDROCK)
				set_pixelv_safe(start + Vector2i(-1,0), BEDROCK)
				set_pixelv_safe(start + Vector2i(0,1), BEDROCK)
				set_pixelv_safe(start + Vector2i(0,-1), BEDROCK)

func set_pixel_safe(x: int, y: int, color: Color) -> void:
	if x >= 0 and x < MAP_SIZE.x and y >= 0 and y < MAP_SIZE.y:
		image.set_pixel(x, y, color)

func set_pixelv_safe(pos: Vector2i, color: Color) -> void:
	set_pixel_safe(pos.x, pos.y, color)
