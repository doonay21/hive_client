extends Node

signal connection_established(user_id: String)
signal connection_error(error_message: String)

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket

func establish_connection() -> void:
	var server_key = Secrets.NAKAMA_SOCKET_SERVER_KEY
	var host = "127.0.0.1"
	var port = 7350
	var scheme = "http"

	client = Nakama.create_client(server_key, host, port, scheme, Nakama.DEFAULT_TIMEOUT, NakamaLogger.LOG_LEVEL.NONE)
	
	var device_id = OS.get_unique_id()
	session = await client.authenticate_device_async(device_id)

	if session.is_exception():
		connection_error.emit(session.get_exception().message)
	else:
		await setup_socket()

func setup_socket():
	socket = Nakama.create_socket_from(client)
	var result: NakamaAsyncResult = await socket.connect_async(session)
	
	if result.is_exception():
		connection_error.emit(session.get_exception().message)
	else:
		connection_established.emit(session.user_id)
