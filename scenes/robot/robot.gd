class_name Robot extends Node2D

@onready var radar_left: Line2D = $RadarLeft
@onready var radar_front: Line2D = $RadarFront
@onready var radar_right: Line2D = $RadarRight

const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var grid_pos: Vector2i = Vector2i(-1, -1)
var map: MapView

var target_global_position: Vector2 = Vector2.ZERO
var target_rotation: float = 0.0
var facing_index: int = 0

var sight: Array[float] = [0.0, 0.0, 0.0]
var front_material: MapView.MaterialType = MapView.MaterialType.VOID
var gold_scanner_values: Array[float] = [0.0, 0.0, 0.0]

var has_moved: bool = false

var interpreter: ProgramInterpreter

func setup(target_map: MapView, start_pos: Vector2i, program_data: Dictionary) -> void:
	map = target_map
	
	if not map.map_changed.is_connected(update_inputs):
		map.map_changed.connect(update_inputs)
		
	set_grid_position(start_pos, true)
	
	interpreter = ProgramInterpreter.new(program_data)
	interpreter.outputs.connect(on_interpreter_outputs)

func _process(_delta: float) -> void:
	global_position = global_position.lerp(target_global_position, 0.3)
	rotation = lerp_angle(rotation, target_rotation, 0.3)

func tick() -> void:
	interpreter.set_inputs(sight, front_material, has_moved, gold_scanner_values, facing_index)
	has_moved = false
	
	interpreter.tick()

func turn_left() -> void:
	facing_index = (facing_index + 3) % 4 
	target_rotation -= PI / 2.0
	update_inputs()

func turn_right() -> void:
	facing_index = (facing_index + 1) % 4
	target_rotation += PI / 2.0
	update_inputs()

func turn_around() -> void:
	facing_index = (facing_index + 2) % 4
	target_rotation += PI
	update_inputs()

func move_forward() -> bool:
	return try_move(DIRS[facing_index])

func move_backward() -> bool:
	var back_index = (facing_index + 2) % 4
	return try_move(DIRS[back_index])

func dig() -> bool:
	if not is_instance_valid(map) or grid_pos == Vector2i(-1, -1):
		return false
		
	var target_pos = grid_pos + DIRS[facing_index]
	
	return map.damage_tile(target_pos)

func set_grid_position(new_pos: Vector2i, instant: bool = false) -> void:
	if grid_pos != Vector2i(-1, -1):
		map.set_tile_v(grid_pos, MapView.MaterialType.VOID)
		
	grid_pos = new_pos
	
	map.set_tile_v(grid_pos, MapView.MaterialType.ROBOT)
	
	if instant:
		global_position = map.tile_map.to_global(map.tile_map.map_to_local(grid_pos))
		target_global_position = global_position
	else:
		target_global_position = map.tile_map.to_global(map.tile_map.map_to_local(grid_pos))
	
	update_inputs()

func try_move(direction: Vector2i) -> bool:
	var target_pos = grid_pos + direction
	
	if map.get_material_at(target_pos) == MapView.MaterialType.VOID:
		set_grid_position(target_pos)
		has_moved = true
		return true
		
	return false

func update_inputs() -> void:
	if not is_instance_valid(map) or grid_pos == Vector2i(-1, -1):
		return
		
	var tile_size: Vector2i = map.tile_map.tile_set.tile_size
	var dir_front = DIRS[facing_index]
	var dir_right = DIRS[(facing_index + 1) % 4]
	var dir_left  = DIRS[(facing_index + 3) % 4]
	
	sight[0] = update_single_radar(radar_left, dir_left,  Vector2i.LEFT, Vector2(-4, 0), tile_size)
	sight[1] = update_single_radar(radar_front, dir_front, Vector2i.UP, Vector2(0, -4), tile_size)
	sight[2] = update_single_radar(radar_right, dir_right, Vector2i.RIGHT, Vector2(4, 0), tile_size)
	
	check_front_material(dir_front)
	update_gold_scanner(dir_front)

func update_single_radar(radar: Line2D, grid_dir: Vector2i, local_dir: Vector2i, start_offset: Vector2, tile_size: Vector2i) -> float:
	var steps: int = 1
	var max_steps: int = 10
	var obstacle_found: bool = false
	
	while steps <= max_steps:
		var check_pos = grid_pos + grid_dir * steps
		
		if not map.map_bounds.has_point(check_pos):
			obstacle_found = true
			break
			
		var mat = map.get_material_at(check_pos)
		if mat != MapView.MaterialType.VOID:
			obstacle_found = true
			break
			
		steps += 1
		
	var sight_value: float = 0.0
	var distance_pixels: float = 0.0
	var tile_dimension = tile_size.x if grid_dir.x != 0 else tile_size.y
	
	if obstacle_found:
		sight_value = 1.0 - (float(steps - 1) / float(max_steps))
		distance_pixels = (steps - 0.5) * tile_dimension
	else:
		sight_value = 0.0
		distance_pixels = max_steps * tile_dimension
		
	distance_pixels = max(distance_pixels, 4.0)
	
	var end_pos = Vector2(local_dir) * distance_pixels
	radar.points = PackedVector2Array([start_offset, end_pos])
	
	return sight_value

func check_front_material(grid_dir: Vector2i) -> void:
	var check_pos = grid_pos + grid_dir
	front_material = map.get_material_at(check_pos)

func update_gold_scanner(grid_dir: Vector2i) -> void:
	gold_scanner_values[0] = scan_mk1()
	gold_scanner_values[1] = scan_mk2()
	gold_scanner_values[2] = scan_mk3(grid_dir)

func scan_mk1() -> float:
	var found_at_dist_2 = false
	
	for x in range(-2, 3):
		for y in range(-2, 3):
			if x == 0 and y == 0: continue
			
			var check_pos = grid_pos + Vector2i(x, y)
			if map.get_material_at(check_pos) == MapView.MaterialType.GOLD:
				if abs(x) <= 1 and abs(y) <= 1:
					return 1.0
				else:
					found_at_dist_2 = true
	
	return 0.5 if found_at_dist_2 else 0.0

func scan_mk2() -> float:
	var max_signal = 0.0
	var r_max = 5.0
	
	for x in range(-5, 6):
		for y in range(-5, 6):
			if x == 0 and y == 0: continue
			
			var vec = Vector2(x, y)
			var dist = vec.length()
			
			if dist > r_max: continue
			
			var check_pos = grid_pos + Vector2i(x, y)
			if map.get_material_at(check_pos) == MapView.MaterialType.GOLD:
				var sig = max(0.0, 1.0 - (dist / r_max))
				if sig > max_signal:
					max_signal = sig
	
	return max_signal

func scan_mk3(grid_dir: Vector2i) -> float:
	for i in range(1, 16):
		var check_pos = grid_pos + grid_dir * i
		
		if map.get_material_at(check_pos) == MapView.MaterialType.GOLD:
			return max(0.0, 1.0 - (float(i - 1) / 15.0))
			
	return 0.0

func on_interpreter_outputs(turn_left_p: float, turn_right_p: float, turn_around_p: float, go_p: float, dig_p: float) -> void:
	var max_signal: float = 0.0 
	var action_to_execute: Callable = Callable() 
	
	var actions: Array[Dictionary] = [
		{"callable": self.dig, "signal": dig_p},
		{"callable": self.turn_right, "signal": turn_left_p},
		{"callable": self.turn_left, "signal": turn_right_p},
		{"callable": self.turn_around, "signal": turn_around_p},
		{"callable": self.move_forward, "signal": go_p}
	]
	
	for action in actions:
		if action["signal"] > max_signal:
			max_signal = action["signal"]
			action_to_execute = action["callable"]
			
	if action_to_execute.is_valid():
		action_to_execute.call()
