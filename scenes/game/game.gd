extends Node2D

var client : NakamaClient
var session : NakamaSession
var socket : NakamaSocket

func _ready():
	var server_key = "6699d654e9ede9d62c477723a667da5e187db1c9712670d894695b64a021962566182cb93f17492858ff85cf5e8efdc3dcdcabfb514774ae7ffc22c59c36d2b3"
	var host = "127.0.0.1"
	var port = 7350
	var scheme = "http"

	client = Nakama.create_client(server_key, host, port, scheme)
	
	var device_id = OS.get_unique_id()
	session = await client.authenticate_device_async(device_id)

	if session.is_exception():
		print("Błąd logowania: ", session.get_exception().message)
	else:
		print("Zalogowano pomyślnie! User ID: ", session.user_id)
		await setup_socket()
		
		save_data()

func setup_socket():
	socket = Nakama.create_socket_from(client)
	var connected : NakamaAsyncResult = await socket.connect_async(session)
	
	if connected.is_exception():
		print("Błąd połączenia socketu: ", connected.get_exception().message)
	else:
		print("Socket połączony i gotowy do gry!")

func save_data() -> void:
	var stats = {
		"level": 10,
		"gold": 500,
		"items": ["miecz", "tarcza"]
	}
	
	var write_obj = NakamaWriteStorageObject.new("user_data", "stats", 1, 1, JSON.stringify(stats), "")
	var result = await client.write_storage_objects_async(session, [write_obj])
	
	if result.is_exception():
		print("Błąd zapisu: ", result.get_exception().message)
	else:
		print("Statystyki zapisane!")
