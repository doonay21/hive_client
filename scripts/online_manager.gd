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

#func save_data() -> void:
	#var stats = {
		#"level": 10,
		#"gold": 500,
		#"items": ["miecz", "tarcza"]
	#}
	#
	#var write_obj = NakamaWriteStorageObject.new("user_data", "stats", 1, 1, JSON.stringify(stats), "")
	#var result = await client.write_storage_objects_async(session, [write_obj])
	#
	#if result.is_exception():
		#print("Błąd zapisu: ", result.get_exception().message)
	#else:
		#print("Statystyki zapisane!")
#
#func call_greet_rpc():
	#var rpc_id = "hello" # To nazwa, którą zarejestrowałeś w Go (InitModule)
	#
	## Go oczekuje stringa z JSONem, więc musimy słownik zamienić na tekst:
	#var payload_dict = { "name": "Gracz Godot" }
	#var payload_string = JSON.stringify(payload_dict)
	#
	#print("Wysyłam RPC: ", rpc_id)
	#
	## Wywołanie asynchroniczne
	#var result : NakamaAPI.ApiRpc = await client.rpc_async(session, rpc_id, payload_string)
	#
	#if result.is_exception():
		#print("Błąd RPC: ", result.get_exception().message)
	#else:
		## Sukces! Odpowiedź jest w result.payload (jako string JSON)
		#print("Surowa odpowiedź z Go: ", result.payload)
		#
		## Parsujemy odpowiedź z powrotem do słownika Godota
		#var json_response = JSON.parse_string(result.payload)
		#
		#if json_response:
			#print("--- WIADOMOŚĆ OD SERWERA ---")
			#print(json_response["message"])
#
#func setup_match():
	## Tworzymy mecz na serwerze. 
	## Nakama użyje Twojego modułu Lua do jego obsługi.
	#var match_join_result = await socket.create_match_async()
	#
	#if match_join_result.is_exception():
		#print("Błąd tworzenia meczu: ", match_join_result.get_exception().message)
	#else:
		#print("Mecz stworzony! ID: ", match_join_result.match_id)
		## Teraz jesteś w meczu i zaczniesz dostawać pakiety danych
