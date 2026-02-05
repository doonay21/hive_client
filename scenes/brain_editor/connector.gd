extends Control

enum ConnectorType {
	In,
	Out
}

@export var connector_type: ConnectorType = ConnectorType.Out:
	set(value):
		connector_type = value
		set_connector_type(value)

@onready var in_texture: TextureRect = $In
@onready var out_texture: TextureRect = $Out

func set_connector_type(value) -> void:
	if not is_node_ready():
		await ready
	
	if value == ConnectorType.In:
		in_texture.show()
		out_texture.hide()
	elif value == ConnectorType.Out:
		in_texture.hide()
		out_texture.show()
