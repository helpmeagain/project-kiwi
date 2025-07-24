extends Control

signal found_server(ip, port, info)
signal update_server(ip, port, info)
signal join_game(ip)

var broadcaster: PacketPeerUDP
var listener: PacketPeerUDP
var room_info = { "name" :  "name", "playerCount": 0 }
var server_last_seen = {}

@export var listenPort: int = 8920
@export var broadcastPort: int = 8930
@export var address: String = "192.168.1.255"
@export var serverInfo: PackedScene

@onready var broadcast_timer: Timer = $BroadcastTimer
@onready var cleanup_timer: Timer = $CleanupTimer
@onready var server_list: VBoxContainer = $ServerInfoPanel/ServerTableContainer/ScrollContainer/ServerListContainer

func _ready():
	cleanup_timer.timeout.connect(_on_cleanup_timer_timeout)

func _process(_delta: float) -> void:
	if listener == null:
		return
	if listener.get_available_packet_count() > 0:
		var server_ip = listener.get_packet_ip()
		var server_port = listener.get_packet_port()
		var bytes = listener.get_packet()
		var data = bytes.get_string_from_utf8()
		var room_info_from_data = JSON.parse_string(data)
		
		# print("[DEBUG] Server IP: " + server_ip + " Server Port: " + str(server_port) + " Room info: " + str(room_info_from_data))
		server_last_seen[server_ip] = Time.get_ticks_msec()
		
		var server_exists = false
		for child in server_list.get_children():
			if child.get_node("IPLabel").text == server_ip:
				update_server.emit(server_ip, server_port, room_info_from_data)
				child.get_node("ServerNameLabel").text = room_info_from_data.name
				child.get_node("PlayerCountLabel").text = str(int(room_info_from_data.playerCount))
				server_exists = true
				break
		
		if not server_exists:
			var currentInfo = serverInfo.instantiate()
			currentInfo.name = room_info_from_data.name
			currentInfo.get_node("ServerNameLabel").text = room_info_from_data.name
			currentInfo.get_node("IPLabel").text = server_ip
			currentInfo.get_node("PlayerCountLabel").text = str(int(room_info_from_data.playerCount))
			server_list.add_child(currentInfo)
			currentInfo.join_game.connect(join_by_ip)
			found_server.emit(server_ip, server_port, room_info_from_data)

func setup_listener():
	listener = PacketPeerUDP.new()
	var ok = listener.bind(listenPort)
	if ok == OK:
		print("Successfully bound to listen Port: " + str(listenPort) + "!")
		cleanup_timer.start()
	else:
		print("Failed to bind to listen Port")

func setup_broadcast(server_name: String):
	room_info.name = server_name
	room_info.playerCount = MultiplayerPlayerManager.players.size()
	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	var listener_address = address
	var ip_parts = address.split(".")
	if ip_parts.size() == 4:
		ip_parts[3] = "255"
		listener_address = ".".join(ip_parts)
	
	broadcaster.set_dest_address(listener_address, listenPort) # mudando para "255.255.255.255" funcionou para um computador apenas
	var ok = broadcaster.bind(broadcastPort)
	if ok == OK:
		print("Successfully bound to broadcast port " + str(broadcastPort) + " !")
	else:
		print("Failed to bind to Broadcast Port")
		
	broadcast_timer.start()

func clean_up():
	broadcast_timer.stop()
	cleanup_timer.stop()
	if listener != null:
		listener.close()
		for child in server_list.get_children():
			child.queue_free()
	if broadcaster != null:
		broadcaster.close()
	server_last_seen.clear()

func _on_broadcast_timer_timeout() -> void:
	room_info.playerCount = MultiplayerPlayerManager.players.size()
	var data = JSON.stringify(room_info)
	var packet = data.to_utf8_buffer()
	broadcaster.put_packet(packet)

func _on_cleanup_timer_timeout() -> void:
	var now = Time.get_ticks_msec()
	var threshold = 3000
	
	var ips_to_remove = []
	for ip in server_last_seen:
		if now - server_last_seen[ip] > threshold:
			ips_to_remove.append(ip)
	
	for ip in ips_to_remove:
		server_last_seen.erase(ip)
		for child in server_list.get_children():
			if child.get_node("IPLabel").text == ip:
				child.queue_free()
				break

func _exit_tree() -> void:
	clean_up()

func join_by_ip(ip):
	join_game.emit(ip)
