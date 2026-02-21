class_name ProgramInterpreter extends Node

var program_data: Dictionary = {}
var robot: Robot

var buffer: Array = []
var columns: int = 7

var sight: Array = [0.0, 0.0, 0.0] # left, front, right

func _init(program_data_p: Dictionary, robot_p: Robot) -> void:
	program_data = program_data_p
	robot = robot_p
	
	columns = ProgramGrid.size_to_dimension(program_data["size"])
	init_buffer()
	tick()

func set_inputs() -> void:
	sight[0] = robot.sense_left()
	sight[1] = robot.sense_forward()
	sight[2] = robot.sense_right()

func set_outputs() -> void:
	pass

func tick() -> void:
	set_inputs()
	
	var counter: int = 0
	
	for y in range(columns):
		for x in range(columns):
			var block: Dictionary = program_data["grid"][counter]
			var op: int = block.get("op", BlockData.Op.NONE)
			var map: Array = block.get("map", [0, 1, 2, 3])
			var val: float = block.get("val", 0.0)
			
			match op:
				BlockData.Op.NONE: pass
				BlockData.Op.SIGHT:
					buffer[x][y][map[3]] = sight[0]
					buffer[x][y][map[0]] = sight[1]
					buffer[x][y][map[1]] = sight[2]
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
					pass
				BlockData.Op.COMPARATOR:
					pass
				BlockData.Op.MINIMUM:
					pass
				BlockData.Op.MAXIMUM:
					pass
				BlockData.Op.ADD:
					pass
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
					pass
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

	set_outputs()

func init_buffer() -> void:
	buffer = create_buffer()

func create_buffer() -> Array:
	var buff: Array = []
	
	for x in range(columns):
		var column: Array = []
		for y in range(columns):
			var ports = [0.0, 0.0, 0.0, 0.0]
			column.append(ports)
		buff.append(column)
	
	return buff

var g = {
	"grid": [
		{  }, {  }, {  }, {  }, {  }, {  }, {  }, {  },
		{ "map": [1, 2, 3, 0], "op": 30 },
		{  }, {  }, {  }, {  }, {  }, {  },
		{ "map": [3, 0, 1, 2], "val": 0.0, "op": 1 },
		{ "map": [0, 1, 2, 3], "op": 32 },
		{  }, {  }, {  }, {  }, {  },
		{ "map": [3, 0, 1, 2], "op": 28 },
		{  }, {  }, {  }, {  }, {  }, {  }, {  }, {  }, {  }, {  }, {  }, {  }, {  },
		{ "map": [0, 1, 2, 3], "val": 0.9, "op": 33 },
		{ "map": [0, 1, 2, 3], "op": 29 },
		{  }, {  }, {  }, {  }, {  }, {  }, {  }, {  }, {  }, {  }, {  }
	],
	"size": 2,
	"custom_blocks": {  } }
