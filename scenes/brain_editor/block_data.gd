class_name BlockData extends Resource

enum Port { NONE, INPUT, OUTPUT }

@export var display_name: String = "Block"
@export var icon: Texture2D
@export var base_color: Color = Color.WHITE

@export var ports: Array[Port] = [Port.NONE, Port.OUTPUT, Port.NONE, Port.NONE]
