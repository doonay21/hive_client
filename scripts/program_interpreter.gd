class_name ProgramInterpreter extends Node

signal outputs(turn_left: float, turn_right: float, turn_around: float, go: float, dig: float)

enum PortDir { TOP = 0, RIGHT = 1, BOTTOM = 2, LEFT = 3 }

const DIR_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), # Górny sąsiad
	Vector2i(1, 0),  # Prawy sąsiad
	Vector2i(0, 1),  # Dolny sąsiad
	Vector2i(-1, 0)  # Lewy sąsiad
]

const MICRO_TICK_MAX: int = 50

var program_data: Dictionary = {}
var columns: int = 7

var read_buffer: PackedFloat64Array
var write_buffer: PackedFloat64Array
var state_buffer: PackedFloat64Array
var delay_buffers: Dictionary = {}

var read_channels: Dictionary = {}
var write_channels: Dictionary = {}

var sight: Array = [0.0, 0.0, 0.0] # left, front, right
var front_material: MapView.MaterialType = MapView.MaterialType.VOID
var can_dig: bool = false
var moved_last_tick: bool = false
var gold_scanner: float = 0.0
var facing_index: int = 0

var output_turn_left: float = 0.0
var output_turn_right: float = 0.0
var output_turn_around: float = 0.0
var output_go: float = 0.0
var output_dig: float = 0.0

var ports_map: Array[Array] = []

func _init(program_data_p: Dictionary) -> void:
	program_data = program_data_p
	columns = ProgramGrid.size_to_dimension(program_data["size"])
	
	init_buffers()
	calculate_ports()

func calculate_ports() -> void:
	ports_map.resize(columns * columns)
	
	var counter: int = 0
	
	for y in range(columns):
		for x in range(columns):
			var block: Dictionary = program_data["grid"][counter]
			var op: int = block.get("op", BlockData.Op.NONE)
			
			if op != BlockData.Op.NONE:
				var map: Array = block.get("map", [0, 1, 2, 3])
				
				var description: Array[int] = [0, 0, 0, 0]
				description[PortDir.TOP] = map.find(0)
				description[PortDir.RIGHT] = map.find(1)
				description[PortDir.BOTTOM] = map.find(2)
				description[PortDir.LEFT] = map.find(3)
				
				ports_map[counter] = description
			
			counter += 1

func init_buffers() -> void:
	var total_size = columns * columns * 4
	
	read_buffer = PackedFloat64Array()
	read_buffer.resize(total_size)
	read_buffer.fill(0.0)
	
	write_buffer = read_buffer.duplicate()
	
	state_buffer = PackedFloat64Array()
	state_buffer.resize(columns * columns * 2)
	state_buffer.fill(0.0)
	
	delay_buffers.clear()
	
	read_channels.clear()
	write_channels.clear()

func get_buffer_index(x: int, y: int, port: int) -> int:
	return (y * columns + x) * 4 + port

func get_state_index(x: int, y: int, var_index: int = 0) -> int:
	return (y * columns + x) * 2 + var_index

func set_inputs(sight_p: Array, front_material_p: MapView.MaterialType, moved_last_tick_p: bool, gold_scanner_p: float, facing_index_p: int) -> void:
	sight = sight_p
	front_material = front_material_p
	can_dig = MapView.MATERIAL_HP.has(front_material)
	moved_last_tick = moved_last_tick_p
	gold_scanner = gold_scanner_p
	facing_index = facing_index_p

func read_neighbor_port(x: int, y: int, my_physical_port: int) -> float:
	var offset: Vector2i = DIR_OFFSETS[my_physical_port]
	var nx: int = x + offset.x
	var ny: int = y + offset.y
	
	if nx < 0 or nx >= columns or ny < 0 or ny >= columns:
		return 0.0
		
	var neighbor_port: int = (my_physical_port + 2) % 4
	var target_index: int = get_buffer_index(nx, ny, neighbor_port)
	
	return read_buffer[target_index]

func tick() -> void:
	for i in range(MICRO_TICK_MAX):
		micro_tick()
		
		if buffers_alike() and channels_alike():
			break
		else:
			var temp = read_buffer
			read_buffer = write_buffer
			write_buffer = temp
			
			var temp_ch = read_channels
			read_channels = write_channels
			write_channels = temp_ch

	update_sequential_states()
	outputs.emit(output_turn_left, output_turn_right, output_turn_around, output_go, output_dig)

func buffers_alike() -> bool:
	for i in range(read_buffer.size()):
		if abs(read_buffer[i] - write_buffer[i]) > 0.001:
			return false
			
	return true

func channels_alike() -> bool:
	if read_channels.size() != write_channels.size(): return false
	for key in read_channels:
		if not write_channels.has(key): return false
		if abs(read_channels[key] - write_channels[key]) > 0.001: return false
	return true

func write_port(x: int, y: int, port: int, value: float) -> void:
	var index: int = get_buffer_index(x, y, port)
	write_buffer[index] = value

func micro_tick() -> void:
	write_buffer.fill(0.0)
	write_channels.clear()
	
	var counter: int = 0
	
	for y in range(columns):
		for x in range(columns):
			var block: Dictionary = program_data["grid"][counter]
			var op: int = block.get("op", BlockData.Op.NONE)
			
			if op != BlockData.Op.NONE:
				var val: float = block.get("val", 0.0)
				var val_i: int = int(val)
				var ports: Array[int] = ports_map[counter]
				
				var top = read_neighbor_port(x, y, ports[PortDir.TOP])
				var left = read_neighbor_port(x, y, ports[PortDir.LEFT])
				var bottom = read_neighbor_port(x, y, ports[PortDir.BOTTOM])
				var right = read_neighbor_port(x, y, ports[PortDir.RIGHT])
				
				match op:
					BlockData.Op.SIGHT:
						write_port(x, y, ports[PortDir.LEFT], sight[0])
						write_port(x, y, ports[PortDir.TOP], sight[1])
						write_port(x, y, ports[PortDir.RIGHT], sight[2])
					BlockData.Op.SENSE:
						var result = 1.0 if front_material == val_i else 0.0
						write_port(x, y, ports[PortDir.TOP], result)
					BlockData.Op.CAN_DIG:
						var result = 1.0 if can_dig else 0.0
						write_port(x, y, ports[PortDir.TOP], result)
					BlockData.Op.MOVED:
						var result = 1.0 if moved_last_tick else 0.0
						write_port(x, y, ports[PortDir.RIGHT], result)
					BlockData.Op.GEO:
						write_port(x, y, ports[PortDir.TOP], gold_scanner)
					BlockData.Op.COMPASS:
						var ew = 0.0
						var ns = 0.0
						
						match facing_index:
							0: # TOP
								ew = 0.5
								ns = 0.0
							1: # RIGHT
								ew = 1.0
								ns = 0.5
							2: # BOTTOM
								ew = 0.5
								ns = 1.0
							3: # LEFT
								ew = 0.0
								ns = 0.5
						
						write_port(x, y, ports[PortDir.RIGHT], ew)
						write_port(x, y, ports[PortDir.BOTTOM], ns)
					BlockData.Op.CLOCK:
						var current_value = state_buffer[get_state_index(x, y, 1)]
						write_port(x, y, ports[PortDir.RIGHT], current_value)
					BlockData.Op.INVERTER:
						var result = 1.0 - left
						write_port(x, y, ports[PortDir.RIGHT], result)
					BlockData.Op.COMPARATOR:
						var result = 1.0 if left > right else 0.0
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.MINIMUM:
						var result = min(left, right)
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.MAXIMUM:
						var result = max(left, right)
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.ADD:
						var result = clamp(left + right, 0.0, 1.0)
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.SUB:
						var result = clamp(left - right, 0.0, 1.0)
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.DIV:
						var result = clamp(left / right, 0.0, 1.0)
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.MUL:
						var result = clamp(left * right, 0.0, 1.0)
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.MODULO:
						var result = clamp(left % right, 0.0, 1.0)
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.AVG:
						var result = (left + right) / 2.0
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.ABS:
						var result = abs(left - right)
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.DELAY:
						var delay_time = int(max(1, val_i))
						var current_value = 0.0
						
						if delay_buffers.has(counter) and delay_buffers[counter].size() >= delay_time:
							current_value = delay_buffers[counter].front()
							
						write_port(x, y, ports[PortDir.RIGHT], current_value)
					BlockData.Op.LATCH:
						var current_memory = state_buffer[get_state_index(x, y, 0)]
						write_port(x, y, ports[PortDir.BOTTOM], current_memory)
					BlockData.Op.COUNTER:
						var current_value = state_buffer[get_state_index(x, y, 1)]
						write_port(x, y, ports[PortDir.BOTTOM], current_value)
					BlockData.Op.SWITCH:
						var result = left if top <= 0.5 else right
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.EDGE:
						var current_value = state_buffer[get_state_index(x, y, 1)]
						write_port(x, y, ports[PortDir.BOTTOM], current_value)
					BlockData.Op.THRESHOLD:
						var state_idx = get_state_index(x, y, 0)
						var current_state = state_buffer[state_idx]
						
						if left > 0.8:
							current_state = 1.0
						elif left < 0.2:
							current_state = 0.0
							
						state_buffer[state_idx] = current_state
						
						write_port(x, y, ports[PortDir.RIGHT], current_state)
					BlockData.Op.EMITTER:
						var channel_key: int = int(round(val * 100.0))
						
						if not write_channels.has(channel_key):
							write_channels[channel_key] = left
						else:
							write_channels[channel_key] = max(write_channels[channel_key], left)
					BlockData.Op.RECEIVER:
						var channel_key: int = int(round(val * 100.0))
						var received_value: float = read_channels.get(channel_key, 0.0)
						
						write_port(x, y, ports[PortDir.RIGHT], received_value)
					BlockData.Op.BROADCAST:
						pass
					BlockData.Op.SCANNER:
						pass
					BlockData.Op.DISH:
						pass
					BlockData.Op.TURN_LEFT:
						output_turn_left = left
					BlockData.Op.GO:
						output_go = left
					BlockData.Op.TURN_RIGHT:
						output_turn_right = left
					BlockData.Op.TURN_AROUND:
						output_turn_around = left
					BlockData.Op.DIG:
						output_dig = left
					BlockData.Op.CONSTANT:
						write_port(x, y, ports[PortDir.RIGHT], val)
					BlockData.Op.SINUS:
						pass
					BlockData.Op.NOISE:
						pass
					BlockData.Op.RANDOM:
						pass
					BlockData.Op.CONNECTION_WE:
						pass
					BlockData.Op.CONNECTION_ES:
						pass
					BlockData.Op.CONNECTION_WS:
						pass
					BlockData.Op.CONNECTION_WES:
						pass
					BlockData.Op.CONNECTION_EWS:
						pass
					BlockData.Op.CONNECTION_CROSS:
						pass
					BlockData.Op.CONNECTION_CROSS_JOINED:
						pass
					BlockData.Op.CUSTOM:
						pass
					_:
						assert(false, "Nieobsłużony operator: %s" % op)
				
			counter += 1

func update_sequential_states() -> void:
	var counter: int = 0
	
	for y in range(columns):
		for x in range(columns):
			var block: Dictionary = program_data["grid"][counter]
			var op: int = block.get("op", BlockData.Op.NONE)
			
			if op != BlockData.Op.NONE:
				var val: float = block.get("val", 0.0)
				var val_i: int = int(val)
				var ports: Array[int] = ports_map[counter]
				
				var top = read_neighbor_port(x, y, ports[PortDir.TOP])
				var left = read_neighbor_port(x, y, ports[PortDir.LEFT])
				var bottom = read_neighbor_port(x, y, ports[PortDir.BOTTOM])
				var right = read_neighbor_port(x, y, ports[PortDir.RIGHT])
				
				match op:
					BlockData.Op.CLOCK:
						var state_counter_idx = get_state_index(x, y, 0)
						var state_value_idx = get_state_index(x, y, 1)
						
						state_buffer[state_counter_idx] += 1
						
						if state_buffer[state_counter_idx] >= val_i:
							state_buffer[state_counter_idx] = 0.0
							state_buffer[state_value_idx] = 1.0
						else:
							state_buffer[state_value_idx] = 0.0
					BlockData.Op.DELAY:
						var delay_time = int(max(1, val_i))
						
						if not delay_buffers.has(counter):
							delay_buffers[counter] = []
							
						var buffer: Array = delay_buffers[counter]
						buffer.push_back(left)
						
						while buffer.size() > delay_time:
							buffer.pop_front()
					BlockData.Op.LATCH:
						var state_idx = get_state_index(x, y, 0)
						var value: float = state_buffer[state_idx]
						
						if left > 0.5 and right > 0.5:
							if left > right:
								value = 1.0
							else:
								value = 0.0
						elif left > 0.5:
							value = 1.0
						elif right > 0.5:
							value = 0.0
						
						state_buffer[state_idx] = value
					BlockData.Op.COUNTER:
						var state_counter_idx = get_state_index(x, y, 0)
						var state_value_idx = get_state_index(x, y, 1)
						
						state_buffer[state_counter_idx] += left
						
						if state_buffer[state_counter_idx] >= 1.0:
							state_buffer[state_counter_idx] -= 1.0
							state_buffer[state_value_idx] = 1.0
						else:
							state_buffer[state_value_idx] = 0.0
					BlockData.Op.EDGE:
						var state_previous_idx = get_state_index(x, y, 0)
						var state_value_idx = get_state_index(x, y, 1)
						
						if state_buffer[state_previous_idx] <= 0.5 and left > 0.5:
							state_buffer[state_value_idx] = 1.0
						else:
							state_buffer[state_value_idx] = 0.0
						
						state_buffer[state_previous_idx] = left
						
			counter += 1
