class_name ProgramInterpreter extends Node

signal outputs

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

var sight: Array = [0.0, 0.0, 0.0] # left, front, right

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

func get_buffer_index(x: int, y: int, port: int) -> int:
	return (y * columns + x) * 4 + port

func get_state_index(x: int, y: int, var_index: int = 0) -> int:
	return (y * columns + x) * 2 + var_index

func set_inputs(sight_p: Array) -> void:
	sight = sight_p

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
		
		if buffers_alike():
			break
		else:
			var temp = read_buffer
			read_buffer = write_buffer
			write_buffer = temp

	update_sequential_states()
	outputs.emit()

func buffers_alike() -> bool:
	for i in range(read_buffer.size()):
		if abs(read_buffer[i] - write_buffer[i]) > 0.001:
			return false
			
	return true

func write_port(x: int, y: int, port: int, value: float) -> void:
	var index: int = get_buffer_index(x, y, port)
	write_buffer[index] = value

func micro_tick() -> void:
	write_buffer.fill(0.0)
	
	var counter: int = 0
	
	for y in range(columns):
		for x in range(columns):
			var block: Dictionary = program_data["grid"][counter]
			var op: int = block.get("op", BlockData.Op.NONE)
			
			if op != BlockData.Op.NONE:
				var val: float = block.get("val", 0.0)
				var ports: Array[int] = ports_map[counter]
				
				match op:
					BlockData.Op.SIGHT:
						write_port(x, y, ports[PortDir.LEFT], sight[0])
						write_port(x, y, ports[PortDir.TOP], sight[1])
						write_port(x, y, ports[PortDir.RIGHT], sight[2])
					BlockData.Op.SENSE:
						pass
					BlockData.Op.CAN_DIG:
						pass
					BlockData.Op.MOVED:
						pass
					BlockData.Op.GEO:
						pass
					BlockData.Op.COMPASS:
						pass
					BlockData.Op.CLOCK:
						pass
					BlockData.Op.INVERTER:
						var in_val = read_neighbor_port(x, y, ports[PortDir.LEFT])
						var result = 1.0 - in_val
						
						write_port(x, y, ports[PortDir.RIGHT], result)
					BlockData.Op.COMPARATOR:
						pass
					BlockData.Op.MINIMUM:
						pass
					BlockData.Op.MAXIMUM:
						pass
					BlockData.Op.ADD:
						var val_a = read_neighbor_port(x, y, ports[PortDir.LEFT])
						var val_b = read_neighbor_port(x, y, ports[PortDir.RIGHT])
						
						var result = val_a + val_b
						
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.SUB:
						pass
					BlockData.Op.DIV:
						pass
					BlockData.Op.MUL:
						pass
					BlockData.Op.MODULO:
						pass
					BlockData.Op.AVG:
						pass
					BlockData.Op.ABS:
						pass
					BlockData.Op.DELAY:
						pass
					BlockData.Op.LATCH:
						var current_memory = state_buffer[get_state_index(x, y, 0)]
						
						write_port(x, y, ports[PortDir.BOTTOM], current_memory)
					BlockData.Op.COUNTER:
						pass
					BlockData.Op.SWITCH:
						pass
					BlockData.Op.EDGE:
						pass
					BlockData.Op.THRESHOLD:
						pass
					BlockData.Op.EMITTER:
						pass
					BlockData.Op.RECEIVER:
						pass
					BlockData.Op.BROADCAST:
						pass
					BlockData.Op.SCANNER:
						pass
					BlockData.Op.DISH:
						pass
					BlockData.Op.TURN_LEFT:
						pass
					BlockData.Op.GO:
						pass
					BlockData.Op.TURN_RIGHT:
						pass
					BlockData.Op.TURN_AROUND:
						pass
					BlockData.Op.DIG:
						pass
					BlockData.Op.CONSTANT:
						pass
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
				var ports: Array[int] = ports_map[counter]
				
				match op:
					BlockData.Op.LATCH:
						var set_signal = read_neighbor_port(x, y, ports[PortDir.LEFT])
						var reset_signal = read_neighbor_port(x, y, ports[PortDir.RIGHT])
						
						if set_signal > 0.5:
							var state_idx = get_state_index(x, y, 0)
							state_buffer[state_idx] = 1.0
						
						if reset_signal > 0.5:
							var state_idx = get_state_index(x, y, 0)
							state_buffer[state_idx] = 0.0
						
			counter += 1
