extends Node

var session: NakamaSession
var client: NakamaClient
var socket: NakamaSocket
var current_match: NakamaRTAPI.Match
var server_connected := false
var is_user_created := false
var _cached_username := ""

signal socket_connected()
signal socket_closed()
signal socket_error(err)
signal notification_received(notification)

func connect_to_server(ip: String, port: int = 7350) -> bool:
	client = Nakama.create_client("defaultkey", ip, port, "http")
	socket = Nakama.create_socket_from(client)
	
	socket.connected.connect(_on_socket_connected)
	socket.closed.connect(_on_socket_closed)
	socket.received_error.connect(_on_socket_error)
	socket.received_notification.connect(_on_notification_received)
	
	#session = await client.authenticate_device_async(OS.get_unique_id())
	var random_number = randi() % 10001
	var email = str(random_number) + "@email.com"
	session = await client.authenticate_email_async(email, "password")
	if session.is_exception():
		push_error("Authentication failed: " + session.get_exception().message)
		return false
	
	var result = await socket.connect_async(session)
	if result.is_exception():
		push_error("Connection failed: " + result.get_exception().message)
		return false
	
	return true

func is_server_connected() -> bool:
	return server_connected and socket != null and socket.is_connected_to_host()

func get_my_username() -> String:
	if _cached_username.is_empty():
		var account = await client.get_account_async(session)
		_cached_username = account.user.username if not account.is_exception() else "Guest"
	return _cached_username

func _on_socket_connected():
	server_connected = true
	emit_signal("socket_connected")

func _on_socket_closed():
	server_connected = false
	emit_signal("socket_closed")

func _on_socket_error(error):
	server_connected = false
	emit_signal("socket_error", error)

func _on_notification_received(notification_data):
	emit_signal("notification_received", notification_data)
