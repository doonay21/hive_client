class_name BlockData extends Resource

enum Port { NONE, INPUT, OUTPUT }
enum Display { ICON_TEXT, BIG_ICON, ICON_VALUE_DRAG }
enum Style { INPUT, FUNCTION, OUTPUT, CONSTANT, CONNECTION, CUSTOM }
enum ValueMode { FLOAT_01, FLOAT_RANGE, INT_RANGE, STRING_LIST }

const COLORS: Dictionary = {
	Style.INPUT: Color("64b5f6"),
	Style.FUNCTION: Color("ba68c8"),
	Style.OUTPUT: Color("81c784"),
	Style.CONSTANT: Color("ffb74d"),
	Style.CONNECTION: Color("90a4ae"),
	Style.CUSTOM: Color("e57373")
}

@export var display_name: String = "Block"
@export var icon: Texture2D
@export var display: Display = Display.ICON_TEXT
@export var style: Style = Style.INPUT
@export var ports: Array[Port] = [Port.NONE, Port.OUTPUT, Port.NONE, Port.NONE]
@export var port_labels: Array[String] = ["", "", "", ""]
@export var info_text: String = ""

@export_group("Value Configuration")
@export var value_mode: ValueMode = ValueMode.FLOAT_01
@export var custom_min: float = 0.0
@export var custom_max: float = 100.0
@export var value_strings: Array[String] = ["Default", "Option 1", "Option 2"]

func get_style_color() -> Color:
	return COLORS.get(style, Color.WHITE)
