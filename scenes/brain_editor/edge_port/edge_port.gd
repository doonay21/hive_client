class_name EdgePort extends MarginContainer

enum Port { NONE, INPUT, OUTPUT }
enum Direction { UP, RIGHT, DOWN, LEFT }

const TEX_NONE = preload("res://assets/images/brain_editor/conn_none.png")
const TEX_IN = preload("res://assets/images/brain_editor/conn_in.png")
const TEX_OUT = preload("res://assets/images/brain_editor/conn_out.png")

@export var port_type: Port = Port.NONE
@export var direction: Direction = Direction.UP

@onready var block: TextureRect = $Control/Block
@onready var port: TextureRect = $Control/Block/Port

var hover_tween: Tween

func _ready() -> void:
	update_visuals()
	
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)

func update_visuals() -> void:
	if not is_node_ready(): return
	
	match port_type:
		Port.NONE: port.texture = TEX_NONE
		Port.INPUT: port.texture = TEX_OUT
		Port.OUTPUT: port.texture = TEX_IN
	
	match direction:
		Direction.UP: block.rotation_degrees = 0
		Direction.RIGHT: block.rotation_degrees = 90
		Direction.DOWN: block.rotation_degrees = 180
		Direction.LEFT: block.rotation_degrees = 270

func on_mouse_entered() -> void:
	if hover_tween: hover_tween.kill()
	
	var port_name: String = ""
	
	match port_type:
		Port.NONE: port_name = tr("BE_EDGE_PORT_NONE")
		Port.INPUT: port_name = tr("BE_EDGE_PORT_INPUT")
		Port.OUTPUT: port_name = tr("BE_EDGE_PORT_OUTPUT")
		
	Events.info_text_requested.emit(tr("BE_EDGE_PORT_INFO").format({ "port_name": port_name }))
	
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "modulate", Color("ffffff80"), 0.2)

func on_mouse_exited() -> void:
	if hover_tween: hover_tween.kill()
	
	Events.info_text_hide_requested.emit()
	
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "modulate", Color("ffffff40"), 0.2)
