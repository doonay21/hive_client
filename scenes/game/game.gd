extends Node2D

var client : NakamaClient
var session : NakamaSession
var socket : NakamaSocket

func _ready():
	pass
	#var server_key = "6699d654e9ede9d62c477723a667da5e187db1c9712670d894695b64a021962566182cb93f17492858ff85cf5e8efdc3dcdcabfb514774ae7ffc22c59c36d2b3"
	#var host = "127.0.0.1"
	#var port = 7350
	#var scheme = "http"
#
	#client = Nakama.create_client(server_key, host, port, scheme)
	#
	#var device_id = OS.get_unique_id()
	#session = await client.authenticate_device_async(device_id)
#
	#if session.is_exception():
		#print("Błąd logowania: ", session.get_exception().message)
	#else:
		#print("Zalogowano pomyślnie! User ID: ", session.user_id)
		#await setup_socket()
		#
		##save_data()
		#call_greet_rpc()
		#
		#socket.received_match_state.connect(on_socket_received_match_state)
		#
		##setup_match()

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

func call_greet_rpc():
	var rpc_id = "hello" # To nazwa, którą zarejestrowałeś w Go (InitModule)
	
	# Go oczekuje stringa z JSONem, więc musimy słownik zamienić na tekst:
	var payload_dict = { "name": "Gracz Godot" }
	var payload_string = JSON.stringify(payload_dict)
	
	print("Wysyłam RPC: ", rpc_id)
	
	# Wywołanie asynchroniczne
	var result : NakamaAPI.ApiRpc = await client.rpc_async(session, rpc_id, payload_string)
	
	if result.is_exception():
		print("Błąd RPC: ", result.get_exception().message)
	else:
		# Sukces! Odpowiedź jest w result.payload (jako string JSON)
		print("Surowa odpowiedź z Go: ", result.payload)
		
		# Parsujemy odpowiedź z powrotem do słownika Godota
		var json_response = JSON.parse_string(result.payload)
		
		if json_response:
			print("--- WIADOMOŚĆ OD SERWERA ---")
			print(json_response["message"])

func setup_match():
	# Tworzymy mecz na serwerze. 
	# Nakama użyje Twojego modułu Lua do jego obsługi.
	var match_join_result = await socket.create_match_async()
	
	if match_join_result.is_exception():
		print("Błąd tworzenia meczu: ", match_join_result.get_exception().message)
	else:
		print("Mecz stworzony! ID: ", match_join_result.match_id)
		# Teraz jesteś w meczu i zaczniesz dostawać pakiety danych

func on_socket_received_match_state(p_match_state) -> void:
	print(p_match_state)
