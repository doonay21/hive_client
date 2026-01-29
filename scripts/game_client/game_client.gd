class_name GameClient extends RefCounted

enum OpCode {
	HANDSHAKE = 1,
	AUTH = 2,
	PLAYER_MOVE = 3,
	CHAT_MESSAGE = 4
}

var websocket_client: WebsocketClient

func _init(client: WebsocketClient) -> void:
	websocket_client = client

func authenticate() -> void:
	var payload: Dictionary = {
		"TOKEN": "abc123"
	}
	
	websocket_client.send(OpCode.AUTH, payload)

func handle_message(message: Dictionary) -> void:
	var opcode = message.get("opcode")

	match opcode:
		OpCode.HANDSHAKE: handle_handshake(message)

func handle_handshake(message: Dictionary) -> void:
	print("Otrzymano Handshake! Wersja serwera: %s" % message.get("version"))
