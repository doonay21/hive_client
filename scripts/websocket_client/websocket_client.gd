class_name WebsocketClient extends RefCounted

signal connected
signal disconnected(code: int, reason: String)
signal data_received(message: Dictionary)
signal error(message: Error)

var websocket_url: String = "ws://127.0.0.1:8181"
var reconnect_interval: float = 3.0

var socket = WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED
var is_reconnecting: bool = false
var reconnect_timestamp: int = 0

var payload_manager: PayloadManager = PayloadManager.new()

func connect_to_host() -> void:
	is_reconnecting = false
	
	socket.close() 
	
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		error.emit(err)
		schedule_reconnect()
	else:
		last_state = WebSocketPeer.STATE_CONNECTING

func close() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.close(1000, "Client closed")

func update() -> void:
	if is_reconnecting and reconnect_timestamp > 0:
		if Time.get_ticks_msec() >= reconnect_timestamp:
			reconnect_timestamp = 0
			connect_to_host()
			return
			
	socket.poll()
	
	var current_state = socket.get_ready_state()
	
	if current_state != last_state:
		handle_state_change(current_state)
		last_state = current_state
	
	if current_state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			handle_data_received(packet)

func handle_state_change(state: int):
	match state:
		WebSocketPeer.STATE_OPEN:
			connected.emit()
		WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			disconnected.emit(code, reason)
			
			schedule_reconnect()

func schedule_reconnect():
	if is_reconnecting:
		return
		
	is_reconnecting = true
	
	@warning_ignore("narrowing_conversion")
	reconnect_timestamp = Time.get_ticks_msec() + (reconnect_interval * 1000)

func handle_data_received(packet: PackedByteArray) -> void:
	var decoded_packet: Dictionary = payload_manager.decode_packet(packet)
	data_received.emit(decoded_packet)
