class_name BlockData extends Resource

enum Port { NONE, INPUT, OUTPUT }
enum Display { ICON_TEXT, BIG_ICON, ICON_VALUE_DRAG }
enum Style { INPUT, FUNCTION, OUTPUT, CONSTANT, CONNECTION }

const COLORS: Dictionary = {
	Style.INPUT: Color("64b5f6"),
	Style.FUNCTION: Color("ba68c8"),
	Style.OUTPUT: Color("81c784"),
	Style.CONSTANT: Color("ffb74d"),
	Style.CONNECTION: Color("90a4ae")
}

@export var display_name: String = "Block"
@export var icon: Texture2D
@export var display: Display = Display.ICON_TEXT
@export var style: Style = Style.INPUT
@export var ports: Array[Port] = [Port.NONE, Port.OUTPUT, Port.NONE, Port.NONE]
@export var port_labels: Array[String] = ["", "", "", ""]
@export var info_text: String = ""

func get_style_color() -> Color:
	return COLORS.get(style, Color.WHITE)
