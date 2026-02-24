class_name ProgramInterpreter extends Node

signal outputs(turn_left: float, turn_right: float, turn_around: float, go: float, dig: float, radio_data: Array, radio_prio: int)

enum PortDir { TOP = 0, RIGHT = 1, BOTTOM = 2, LEFT = 3 }

const DIR_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0)
]

const MICRO_TICK_MAX: int = 50
const SINUS_PERIOD: float = 40.0
const SIGNAL_FALLOFF: float = 0.05

var program_data: Dictionary = {}
var columns: int = 7

var is_main: bool = true
var parent_interpreter: ProgramInterpreter = null
var sub_interpreters: Dictionary = {}

var custom_block_ports: Dictionary = {} 

var external_inputs: Array[float] = [0.0, 0.0, 0.0, 0.0]

var op_array: PackedInt32Array
var val_array: PackedFloat64Array

var rw_buffers: Array[PackedFloat64Array] = [PackedFloat64Array(), PackedFloat64Array()]
var read_idx: int = 0
var write_idx: int = 1

var state_buffer: PackedFloat64Array
var delay_buffers: Dictionary = {}

var read_channels: Dictionary = {}
var write_channels: Dictionary = {}

var sight: Array = [0.0, 0.0, 0.0, 0.0]
var front_material: MapView.MaterialType = MapView.MaterialType.VOID
var can_dig: bool = false
var moved_last_tick: bool = false
var gold_scanner: Array[float] = [0.0, 0.0, 0.0]
var facing_index: int = 0
var robot_id: float = 0.0
var robot_gps_data: Array[float] = [0.0, 0.0]
var radio_rx_data: Array[float] = [0.0, 0.0, 0.0, 0.0] # Dane odebrane z eteru

var output_turn_left: float = 0.0
var output_turn_right: float = 0.0
var output_turn_around: float = 0.0
var output_go: float = 0.0
var output_dig: float = 0.0
var output_radio_tx: Array[float] = [0.0, 0.0, 0.0, 0.0] # Sygnały do wysłania [Top, Right, Bottom, Left]
var output_radio_prio: int = 0

var ports_map: Array[Array] = []

func _init(data: Dictionary, is_main_p: bool = true, parent_p: ProgramInterpreter = null) -> void:
	program_data = data
	is_main = is_main_p
	parent_interpreter = parent_p
	columns = ProgramGrid.size_to_dimension(program_data["size"])
	
	init_op_val_arrays()
	init_buffers()
	calculate_ports()

func get_root_data() -> Dictionary:
	if is_main: return program_data
	return parent_interpreter.get_root_data()

func init_op_val_arrays() -> void:
	op_array.resize(columns * columns)
	val_array.resize(columns * columns)
	
	var counter: int = 0
	for y in range(columns):
		for x in range(columns):
			var block: Dictionary = program_data["grid"][counter]
			var op: int = block.get("op", BlockData.Op.NONE)
			op_array[counter] = op
			
			if op != BlockData.Op.NONE:
				var val: float = block.get("val", 0.0)
				val_array[counter] = val
				
				if op == BlockData.Op.CUSTOM:
					var uuid = block.get("uuid")
					var root_data = get_root_data()
					
					if root_data["custom_blocks"].has(uuid):
						var cb_data = root_data["custom_blocks"][uuid]
						sub_interpreters[counter] = ProgramInterpreter.new(cb_data, false, self)
					
					var block_res = BlockLibrary.get_custom_block_data(uuid)
					if block_res:
						custom_block_ports[counter] = block_res.ports
					else:
						custom_block_ports[counter] = [0, 0, 0, 0]
			
			counter += 1

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
	rw_buffers[read_idx].resize(total_size)
	rw_buffers[read_idx].fill(0.0)
	rw_buffers[write_idx] = rw_buffers[read_idx].duplicate()
	
	state_buffer = PackedFloat64Array()
	state_buffer.resize(columns * columns * 2)
	state_buffer.fill(0.0)
	
	delay_buffers.clear()
	if is_main:
		read_channels.clear()
		write_channels.clear()

func get_buffer_index(x: int, y: int, port: int) -> int:
	return (y * columns + x) * 4 + port

func get_state_index(x: int, y: int, var_index: int = 0) -> int:
	return (y * columns + x) * 2 + var_index

func set_inputs(inputs: Dictionary) -> void:
	sight = inputs.get("sight", [0.0, 0.0, 0.0, 0.0]) as Array
	front_material = inputs.get("front_material", MapView.MaterialType.VOID) as MapView.MaterialType
	can_dig = inputs.get("can_dig", false) as bool
	moved_last_tick = inputs.get("moved_last_tick", false) as bool
	gold_scanner = inputs.get("gold_scanner", [0.0, 0.0, 0.0]) as Array[float]
	facing_index = inputs.get("facing_index", 0) as int
	robot_id = inputs.get("id", 0.0) as float
	robot_gps_data = inputs.get("gps", [0.0, 0.0]) as Array[float]
	radio_rx_data = inputs.get("radio_rx", [0.0, 0.0, 0.0, 0.0]) as Array[float]

func get_sight() -> Array: return sight if is_main else parent_interpreter.get_sight()
func get_front_material() -> MapView.MaterialType: return front_material if is_main else parent_interpreter.get_front_material()
func get_can_dig() -> bool: return can_dig if is_main else parent_interpreter.get_can_dig()
func get_moved_last_tick() -> bool: return moved_last_tick if is_main else parent_interpreter.get_moved_last_tick()
func get_gold_scanner() -> Array[float]: return gold_scanner if is_main else parent_interpreter.get_gold_scanner()
func get_facing_index() -> int: return facing_index if is_main else parent_interpreter.get_facing_index()
func get_read_channels() -> Dictionary: return read_channels if is_main else parent_interpreter.get_read_channels()
func get_radio_rx_data() -> Array[float]: return radio_rx_data if is_main else parent_interpreter.get_radio_rx_data()

func write_channel(key: int, val: float) -> void:
	if is_main:
		if not write_channels.has(key): write_channels[key] = val
		else: write_channels[key] = max(write_channels[key], val)
	else: parent_interpreter.write_channel(key, val)

func add_output_turn_left(val: float) -> void:
	if is_main: output_turn_left = max(output_turn_left, val)
	else: parent_interpreter.add_output_turn_left(val)

func add_output_turn_right(val: float) -> void:
	if is_main: output_turn_right = max(output_turn_right, val)
	else: parent_interpreter.add_output_turn_right(val)

func add_output_turn_around(val: float) -> void:
	if is_main: output_turn_around = max(output_turn_around, val)
	else: parent_interpreter.add_output_turn_around(val)

func add_output_go(val: float) -> void:
	if is_main: output_go = max(output_go, val)
	else: parent_interpreter.add_output_go(val)

func add_output_dig(val: float) -> void:
	if is_main: output_dig = max(output_dig, val)
	else: parent_interpreter.add_output_dig(val)

func add_output_radio(slot_idx: int, val: float, priority: int) -> void:
	if is_main:
		output_radio_tx[slot_idx] = max(output_radio_tx[slot_idx], val)
		output_radio_prio = max(output_radio_prio, priority) 
	else:
		parent_interpreter.add_output_radio(slot_idx, val, priority)

func read_neighbor_port(x: int, y: int, my_physical_port: int) -> float:
	var offset: Vector2i = DIR_OFFSETS[my_physical_port]
	var nx: int = x + offset.x
	var ny: int = y + offset.y
	
	if nx < 0 or nx >= columns or ny < 0 or ny >= columns:
		if not is_main:
			@warning_ignore("integer_division")
			var center: int = columns / 2
			if my_physical_port == PortDir.TOP and x == center and y == 0: return external_inputs[PortDir.TOP]
			if my_physical_port == PortDir.RIGHT and x == columns - 1 and y == center: return external_inputs[PortDir.RIGHT]
			if my_physical_port == PortDir.BOTTOM and x == center and y == columns - 1: return external_inputs[PortDir.BOTTOM]
			if my_physical_port == PortDir.LEFT and x == 0 and y == center: return external_inputs[PortDir.LEFT]
		return 0.0
		
	var neighbor_port: int = (my_physical_port + 2) % 4
	var target_index: int = get_buffer_index(nx, ny, neighbor_port)
	return rw_buffers[read_idx][target_index]

func get_edge_outputs() -> Array[float]:
	@warning_ignore("integer_division")
	var center: int = columns / 2
	var max_idx: int = columns - 1
	return [
		rw_buffers[write_idx][get_buffer_index(center, 0, PortDir.TOP)],
		rw_buffers[write_idx][get_buffer_index(max_idx, center, PortDir.RIGHT)],
		rw_buffers[write_idx][get_buffer_index(center, max_idx, PortDir.BOTTOM)],
		rw_buffers[write_idx][get_buffer_index(0, center, PortDir.LEFT)]
	]

func tick() -> void:
	if not is_main: return

	for i in range(MICRO_TICK_MAX):
		micro_tick()
		
		if is_fully_stable():
			break
		else:
			swap_buffers_recursive()

	update_sequential_states_recursive()
	
	if is_main:
		outputs.emit(output_turn_left, output_turn_right, output_turn_around, output_go, output_dig, output_radio_tx, output_radio_prio)

func is_fully_stable() -> bool:
	if not buffers_alike(): return false
	if is_main and not channels_alike(): return false
	for sub in sub_interpreters.values():
		if not sub.is_fully_stable(): return false
	return true

func swap_buffers_recursive() -> void:
	read_idx = 1 - read_idx
	write_idx = 1 - write_idx
	if is_main:
		var temp_ch = read_channels
		read_channels = write_channels
		write_channels = temp_ch
		
	for sub in sub_interpreters.values():
		sub.swap_buffers_recursive()

func update_sequential_states_recursive() -> void:
	update_sequential_states()
	for sub in sub_interpreters.values():
		sub.update_sequential_states_recursive()

func buffers_alike() -> bool:
	for i in range(rw_buffers[read_idx].size()):
		if abs(rw_buffers[read_idx][i] - rw_buffers[write_idx][i]) > 0.001:
			return false
	return true

func channels_alike() -> bool:
	if read_channels.size() != write_channels.size(): return false
	for key in read_channels:
		if not write_channels.has(key): return false
		if abs(read_channels[key] - write_channels[key]) > 0.001: return false
	return true

func snap_signal(value: float) -> float:
	return snappedf(clampf(value, 0.0, 1.0), Hive.PRECISION_STEP)

func write_port(x: int, y: int, port: int, value: float) -> void:
	var index: int = get_buffer_index(x, y, port)
	rw_buffers[write_idx][index] = snap_signal(value)

func micro_tick() -> void:
	rw_buffers[write_idx].fill(0.0)
	
	if is_main:
		write_channels.clear()
		output_turn_left = 0.0
		output_turn_right = 0.0
		output_turn_around = 0.0
		output_go = 0.0
		output_dig = 0.0
		output_radio_tx = [0.0, 0.0, 0.0, 0.0]
		output_radio_prio = 0
	
	var counter: int = 0
	for y in range(columns):
		for x in range(columns):
			var op: int = op_array[counter]
			
			if op != BlockData.Op.NONE:
				var val: float = val_array[counter]
				var val_i: int = int(val)
				var ports: Array[int] = ports_map[counter]
				
				var top = read_neighbor_port(x, y, ports[PortDir.TOP])
				var left = read_neighbor_port(x, y, ports[PortDir.LEFT])
				var right = read_neighbor_port(x, y, ports[PortDir.RIGHT])
				var bottom = read_neighbor_port(x, y, ports[PortDir.BOTTOM])
				
				match op:
					BlockData.Op.SIGHT:
						write_port(x, y, ports[PortDir.LEFT], get_sight()[0])
						write_port(x, y, ports[PortDir.TOP], get_sight()[1])
						write_port(x, y, ports[PortDir.RIGHT], get_sight()[2])
					BlockData.Op.SENSE:
						var result = 1.0 if get_front_material() == val_i else 0.0
						write_port(x, y, ports[PortDir.TOP], result)
					BlockData.Op.CAN_DIG:
						var result = 1.0 if get_can_dig() else 0.0
						write_port(x, y, ports[PortDir.TOP], result)
					BlockData.Op.MOVED:
						var result = 1.0 if get_moved_last_tick() else 0.0
						write_port(x, y, ports[PortDir.RIGHT], result)
					BlockData.Op.GEO_MK1:
						var scanners = get_gold_scanner()
						write_port(x, y, ports[PortDir.RIGHT], scanners[0])
					BlockData.Op.GEO_MK2:
						var scanners = get_gold_scanner()
						write_port(x, y, ports[PortDir.RIGHT], scanners[1])
					BlockData.Op.GEO_MK3:
						var scanners = get_gold_scanner()
						write_port(x, y, ports[PortDir.RIGHT], scanners[2])
					BlockData.Op.COMPASS:
						var ew = 0.0
						var ns = 0.0
						match get_facing_index():
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
						var result = clamp(left / right, 0.0, 1.0) if right != 0 else 0.0
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.MUL:
						var result = clamp(left * right, 0.0, 1.0)
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.MODULO:
						var result = clamp(left % right, 0.0, 1.0) if right != 0 else 0.0
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
						if left > 0.8: current_state = 1.0
						elif left < 0.2: current_state = 0.0
						state_buffer[state_idx] = current_state
						write_port(x, y, ports[PortDir.RIGHT], current_state)
					BlockData.Op.EMITTER:
						var channel_key: int = int(round(val * 100.0))
						write_channel(channel_key, left)
					BlockData.Op.RECEIVER:
						var channel_key: int = int(round(val * 100.0))
						var received_value: float = get_read_channels().get(channel_key, 0.0)
						write_port(x, y, ports[PortDir.RIGHT], received_value)
					BlockData.Op.TURN_LEFT:
						add_output_turn_left(left)
					BlockData.Op.GO:
						add_output_go(left)
					BlockData.Op.TURN_RIGHT:
						add_output_turn_right(left)
					BlockData.Op.TURN_AROUND:
						add_output_turn_around(left)
					BlockData.Op.DIG:
						add_output_dig(left)
					BlockData.Op.CONSTANT:
						write_port(x, y, ports[PortDir.RIGHT], val)
					BlockData.Op.SINUS:
						var state_idx = get_state_index(x, y, 0)
						var current_tick = state_buffer[state_idx]
						var phase = current_tick / SINUS_PERIOD
						var result = (sin(phase * TAU) + 1.0) / 2.0
						write_port(x, y, ports[PortDir.RIGHT], result)
					BlockData.Op.RANDOM:
						var random_value = state_buffer[get_state_index(x, y, 0)]
						write_port(x, y, ports[PortDir.RIGHT], random_value)
					BlockData.Op.CONNECTION_WE:
						write_port(x, y, ports[PortDir.RIGHT], left)
					BlockData.Op.CONNECTION_ES:
						write_port(x, y, ports[PortDir.BOTTOM], right)
					BlockData.Op.CONNECTION_WS:
						write_port(x, y, ports[PortDir.BOTTOM], left)
					BlockData.Op.CONNECTION_WES:
						write_port(x, y, ports[PortDir.RIGHT], left)
						write_port(x, y, ports[PortDir.BOTTOM], left)
					BlockData.Op.CONNECTION_EWS:
						write_port(x, y, ports[PortDir.LEFT], right)
						write_port(x, y, ports[PortDir.BOTTOM], left)
					BlockData.Op.CONNECTION_CROSS:
						write_port(x, y, ports[PortDir.RIGHT], left)
						write_port(x, y, ports[PortDir.BOTTOM], top)
					BlockData.Op.CONNECTION_CROSS_JOINED:
						write_port(x, y, ports[PortDir.RIGHT], top)
						write_port(x, y, ports[PortDir.BOTTOM], top)
						write_port(x, y, ports[PortDir.LEFT], top)
					BlockData.Op.BEHIND:
						write_port(x, y, ports[PortDir.BOTTOM], get_sight()[3])
					BlockData.Op.RADIO_TX:
						add_output_radio(0, top, val_i)
						add_output_radio(1, right, val_i)
						add_output_radio(2, bottom, val_i)
						add_output_radio(3, left, val_i)
					BlockData.Op.RADIO_RX:
						var radio_signals = get_radio_rx_data()
						write_port(x, y, ports[PortDir.TOP], radio_signals[0])
						write_port(x, y, ports[PortDir.RIGHT], radio_signals[1])
						write_port(x, y, ports[PortDir.BOTTOM], radio_signals[2])
						write_port(x, y, ports[PortDir.LEFT], radio_signals[3])
					BlockData.Op.GPS:
						write_port(x, y, ports[PortDir.RIGHT], robot_gps_data[0])
						write_port(x, y, ports[PortDir.BOTTOM], robot_gps_data[1])
					BlockData.Op.ID:
						write_port(x, y, ports[PortDir.BOTTOM], robot_id)
					BlockData.Op.EQ:
						var result = 1.0 if abs(left - right) < 0.001 else 0.0
						write_port(x, y, ports[PortDir.BOTTOM], result)
					BlockData.Op.DELTA:
						var result = ((top - bottom) * 0.5) + 0.5
						write_port(x, y, ports[PortDir.RIGHT], result)
					BlockData.Op.AZIMUTH:
						var dy = (top - 0.5) * 2.0
						var dx = (left - 0.5) * 2.0
						var angle_rad = atan2(dy, dx)
						var normalized_angle = fposmod(angle_rad + PI / 2.0, TAU) / TAU
						
						write_port(x, y, ports[PortDir.BOTTOM], normalized_angle)
					BlockData.Op.SQRT:
						var result = sqrt(left)
						write_port(x, y, ports[PortDir.RIGHT], result)
					BlockData.Op.MEMORY:
						var current_memory = state_buffer[get_state_index(x, y, 0)]
						write_port(x, y, ports[PortDir.RIGHT], current_memory)
					BlockData.Op.CUSTOM:
						var sub: ProgramInterpreter = sub_interpreters[counter]
						var def_ports: Array = custom_block_ports.get(counter, [0, 0, 0, 0])
						
						sub.external_inputs[PortDir.TOP] = top if def_ports[PortDir.TOP] == BlockData.Port.INPUT else 0.0
						sub.external_inputs[PortDir.RIGHT] = right if def_ports[PortDir.RIGHT] == BlockData.Port.INPUT else 0.0
						sub.external_inputs[PortDir.BOTTOM] = bottom if def_ports[PortDir.BOTTOM] == BlockData.Port.INPUT else 0.0
						sub.external_inputs[PortDir.LEFT] = left if def_ports[PortDir.LEFT] == BlockData.Port.INPUT else 0.0
						
						sub.micro_tick()
						
						var sub_outs = sub.get_edge_outputs()
						
						if def_ports[PortDir.TOP] == BlockData.Port.OUTPUT:
							write_port(x, y, ports[PortDir.TOP], sub_outs[PortDir.TOP])
							
						if def_ports[PortDir.RIGHT] == BlockData.Port.OUTPUT:
							write_port(x, y, ports[PortDir.RIGHT], sub_outs[PortDir.RIGHT])
							
						if def_ports[PortDir.BOTTOM] == BlockData.Port.OUTPUT:
							write_port(x, y, ports[PortDir.BOTTOM], sub_outs[PortDir.BOTTOM])
							
						if def_ports[PortDir.LEFT] == BlockData.Port.OUTPUT:
							write_port(x, y, ports[PortDir.LEFT], sub_outs[PortDir.LEFT])
					_:
						assert(false, "Nieobsłużony operator: %s" % op)
			counter += 1

func update_sequential_states() -> void:
	var counter: int = 0
	for y in range(columns):
		for x in range(columns):
			var op: int = op_array[counter]
			if op != BlockData.Op.NONE:
				var val: float = val_array[counter]
				var val_i: int = int(val)
				var ports: Array[int] = ports_map[counter]
				
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
						var left = read_neighbor_port(x, y, ports[PortDir.LEFT])
						var delay_time = int(max(1, val_i))
						if not delay_buffers.has(counter):
							delay_buffers[counter] = []
						var buffer: Array = delay_buffers[counter]
						buffer.push_back(left)
						while buffer.size() > delay_time:
							buffer.pop_front()
					BlockData.Op.LATCH:
						var left = read_neighbor_port(x, y, ports[PortDir.LEFT])
						var right = read_neighbor_port(x, y, ports[PortDir.RIGHT])
						var state_idx = get_state_index(x, y, 0)
						var value: float = state_buffer[state_idx]
						if left > 0.5 and right > 0.5:
							value = 1.0 if left > right else 0.0
						elif left > 0.5: value = 1.0
						elif right > 0.5: value = 0.0
						state_buffer[state_idx] = value
					BlockData.Op.COUNTER:
						var left = read_neighbor_port(x, y, ports[PortDir.LEFT])
						var state_counter_idx = get_state_index(x, y, 0)
						var state_value_idx = get_state_index(x, y, 1)
						state_buffer[state_counter_idx] += left
						if state_buffer[state_counter_idx] >= 1.0:
							state_buffer[state_counter_idx] -= 1.0
							state_buffer[state_value_idx] = 1.0
						else:
							state_buffer[state_value_idx] = 0.0
					BlockData.Op.EDGE:
						var left = read_neighbor_port(x, y, ports[PortDir.LEFT])
						var state_previous_idx = get_state_index(x, y, 0)
						var state_value_idx = get_state_index(x, y, 1)
						if state_buffer[state_previous_idx] <= 0.5 and left > 0.5:
							state_buffer[state_value_idx] = 1.0
						else:
							state_buffer[state_value_idx] = 0.0
						state_buffer[state_previous_idx] = left
					BlockData.Op.SINUS:
						var state_idx = get_state_index(x, y, 0)
						state_buffer[state_idx] = fmod(state_buffer[state_idx] + 1.0, SINUS_PERIOD)
					BlockData.Op.RANDOM:
						var left = read_neighbor_port(x, y, ports[PortDir.LEFT])
						var state_idx = get_state_index(x, y, 0)
						if left > 0.5:
							state_buffer[state_idx] = randf()
					BlockData.Op.MEMORY:
						var left = read_neighbor_port(x, y, ports[PortDir.LEFT])
						var top = read_neighbor_port(x, y, ports[PortDir.TOP])
						var state_idx = get_state_index(x, y, 0)
						var value: float = state_buffer[state_idx]
						
						if top > 0.5:
							value = left
						
						state_buffer[state_idx] = value
			counter += 1
