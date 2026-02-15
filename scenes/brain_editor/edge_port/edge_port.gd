class_name EdgePort extends Control

signal port_type_changed()

const TEX_NONE = preload("res://assets/images/brain_editor/edge_port_none.png")
const TEX_IN = preload("res://assets/images/brain_editor/edge_port_in.png")
const TEX_OUT = preload("res://assets/images/brain_editor/edge_port_out.png")

@export var port_type: BlockData.Port = BlockData.Port.NONE

@onready var texture: TextureRect = $TextureRect

var hover_tween: Tween

func _ready() -> void:
	update_visuals()
	
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)

func change_type(new_port_type: BlockData.Port) -> void:
	if port_type == new_port_type: return
	
	port_type = new_port_type
	update_visuals()
	
	port_type_changed.emit()

func update_visuals() -> void:
	if not is_node_ready(): return
	
	match port_type:
		BlockData.Port.NONE: texture.texture = TEX_NONE
		BlockData.Port.INPUT: texture.texture = TEX_IN
		BlockData.Port.OUTPUT: texture.texture = TEX_OUT

func on_mouse_entered() -> void:
	if hover_tween: hover_tween.kill()
	
	var port_name: String = ""
	
	match port_type:
		BlockData.Port.NONE: port_name = tr("brain_editor.edge_port.none")
		BlockData.Port.INPUT: port_name = tr("brain_editor.edge_port.input")
		BlockData.Port.OUTPUT: port_name = tr("brain_editor.edge_port.output")
		
	Events.info_text_requested.emit(tr("brain_editor.edge_port.info").format({ "port_name": port_name }))
	
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "modulate", Color("ffffff80"), 0.2)

func on_mouse_exited() -> void:
	if hover_tween: hover_tween.kill()
	
	Events.info_text_hide_requested.emit()
	
	hover_tween = create_tween()
	hover_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "modulate", Color("ffffff40"), 0.2)
