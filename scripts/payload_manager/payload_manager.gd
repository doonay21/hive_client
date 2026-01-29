class_name PayloadManager extends RefCounted

var buffer: StreamPeerBuffer = StreamPeerBuffer.new()

func _init() -> void:
	buffer.big_endian = false 

func encode_packet(opcode: GameClient.OpCode, data: Dictionary = {}) -> PackedByteArray:
	buffer.clear()
	buffer.put_32(0) # Placeholder for packet size
	buffer.put_32(opcode)
	
	match opcode:
		GameClient.OpCode.HANDSHAKE:
			buffer.put_string(data.get("version", "1.0"))
		GameClient.OpCode.PLAYER_MOVE:
			# Przykład: ID gracza (int), Pozycja X (float), Pozycja Y (float)
			buffer.put_32(data.get("id", 0))
			buffer.put_float(data.get("x", 0.0))
			buffer.put_float(data.get("y", 0.0))
			
	var total_size = buffer.get_position()
	var payload_size = total_size - 4
	
	buffer.seek(0)
	buffer.put_32(payload_size)
	
	return buffer.data_array

func decode_packet(bytes: PackedByteArray) -> Dictionary:
	buffer.data_array = bytes
	buffer.seek(0)
	
	if buffer.get_size() < 8:
		return {}

	var _packet_size = buffer.get_32()
	var opcode = buffer.get_32()
	var result = {"opcode": opcode}
	
	match opcode:
		GameClient.OpCode.HANDSHAKE:
			result["version"] = buffer.get_string()
		GameClient.OpCode.PLAYER_MOVE:
			result["id"] = buffer.get_32()
			result["x"] = buffer.get_float()
			result["y"] = buffer.get_float()
		GameClient.OpCode.CHAT_MESSAGE:
			result["msg"] = buffer.get_string()
			
	return result
