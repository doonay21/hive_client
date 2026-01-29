class_name GameClient extends RefCounted

enum OpCode {
	HANDSHAKE = 1,
	PLAYER_MOVE = 2,
	CHAT_MESSAGE = 3
}

func handle_message(message: Dictionary) -> void:
	var opcode = message.get("opcode")

	match opcode:
		OpCode.HANDSHAKE: handle_handshake(message)

func handle_handshake(message: Dictionary) -> void:
	print("Otrzymano Handshake! Wersja serwera: %s" % message.get("version"))
