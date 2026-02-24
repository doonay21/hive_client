class_name BlockData extends Resource

enum Port { NONE, INPUT, OUTPUT }
enum Display { ICON_TEXT, BIG_ICON, ICON_VALUE_DRAG }
enum Style { INPUT, FUNCTION, OUTPUT, CONSTANT, CONNECTION, CUSTOM }
enum ValueMode { FLOAT_01, FLOAT_RANGE, INT_RANGE, STRING_LIST }

enum Op {
	NONE = 0,
	SIGHT = 1,
	MOVED = 2,
	GEO_MK1 = 3,
	COMPASS = 4,
	CLOCK = 5,
	INVERTER = 6,
	COMPARATOR = 7,
	MINIMUM = 8,
	MAXIMUM = 9,
	ADD = 10,
	SUB = 11,
	DIV = 12,
	MUL = 13,
	MODULO = 14,
	AVG = 15,
	ABS = 16,
	DELAY = 17,
	LATCH = 18,
	COUNTER = 19,
	SWITCH = 20,
	EDGE = 21,
	THRESHOLD = 22,
	EMITTER = 23,
	RECEIVER = 24,
	TURN_LEFT = 28,
	GO = 29,
	TURN_RIGHT = 30,
	TURN_AROUND = 31,
	DIG = 32,
	CONSTANT = 33,
	SINUS = 34,
	NOISE = 35,
	RANDOM = 36,
	CONNECTION_WE = 37,
	CONNECTION_ES = 38,
	CONNECTION_WS = 39,
	CONNECTION_WES = 40,
	CONNECTION_EWS = 41,
	CONNECTION_CROSS = 42,
	CONNECTION_CROSS_JOINED = 43,
	SENSE = 44,
	CAN_DIG = 45,
	GEO_MK2 = 46,
	GEO_MK3 = 47,
	BEHIND = 48,
	RADIO_TX = 49,
	RADIO_RX = 50,
	GPS = 51,
	ID = 52,
	EQ = 53,
	CUSTOM = 0xFFFFFFFF
}

const COLORS: Dictionary = {
	Style.INPUT: Color("64b5f6"),
	Style.FUNCTION: Color("ba68c8"),
	Style.OUTPUT: Color("81c784"),
	Style.CONSTANT: Color("ffb74d"),
	Style.CONNECTION: Color("90a4ae"),
	Style.CUSTOM: Color("e57373")
}

@export var display_name: String = "Block"
@export var op: Op = Op.NONE
@export var icon: Texture2D
@export var display: Display = Display.ICON_TEXT
@export var style: Style = Style.INPUT
@export var ports: Array = [Port.NONE, Port.OUTPUT, Port.NONE, Port.NONE]
@export var port_labels: Array[String] = ["", "", "", ""]
@export var info_text: String = ""

@export_group("Value Configuration")
@export var value_mode: ValueMode = ValueMode.FLOAT_01
@export var custom_min: float = 0.0
@export var custom_max: float = 100.0
@export var value_strings: Array[String] = ["Default", "Option 1", "Option 2"]

func get_style_color() -> Color:
	return COLORS.get(style, Color.WHITE)
