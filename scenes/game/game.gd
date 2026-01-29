extends Node2D

var websocket_client: WebsocketClient
var game_client: GameClient

func _ready():
	websocket_client = WebsocketClient.new()
	websocket_client.connected.connect(on_websocket_client_connected)
	websocket_client.disconnected.connect(on_websocket_client_disconnected)
	websocket_client.data_received.connect(on_websocket_client_data_received)
	
	game_client = GameClient.new()
	
	websocket_client.connect_to_host()

func _process(_delta: float) -> void:
	websocket_client.update()

func _exit_tree() -> void:
	websocket_client.close()

func on_websocket_client_connected() -> void:
	print("WS connected!")

func on_websocket_client_disconnected(code: int, reason: String) -> void:
	print("WS disconnected! code = %s, reason = %s" % [code, reason])

func on_websocket_client_data_received(message: Dictionary) -> void:
	game_client.handle_message(message)
