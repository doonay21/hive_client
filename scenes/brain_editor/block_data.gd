class_name BlockData extends Resource

enum Port { NONE, INPUT, OUTPUT }
enum Display { ICON_TEXT, BIG_ICON }
enum Style { INPUT, FUNCTION, OUTPUT, CONSTANT, CONNECTION }

const COLORS: Dictionary = {
	Style.INPUT: Color("00e5ff"),
	Style.FUNCTION: Color("d500f9"),
	Style.OUTPUT: Color("76ff03"),
	Style.CONSTANT: Color("ff9100"),
	Style.CONNECTION: Color("607d8b")
}

@export var display_name: String = "Block"
@export var icon: Texture2D
@export var display: Display = Display.ICON_TEXT
@export var style: Style = Style.INPUT

@export var ports: Array[Port] = [Port.NONE, Port.OUTPUT, Port.NONE, Port.NONE]

func get_style_color() -> Color:
	return COLORS[style]
