extends Control

signal found_server(ip, port, info)
signal update_server(ip, port, info)
signal join_game(ip)

var broadcast_timer: Timer
var broadcaster: PacketPeerUDP
var listener: PacketPeerUDP
var room_info = { "name" :  "name", "playerCount": 0 }
@export var listenPort: int = 8920
@export var broadcastPort: int = 8930
@export var broadcastAddress: String = "192.168.1.255"
@export var serverInfo: PackedScene

func _ready() -> void:
	broadcast_timer = $BroadcastTimer
	setup_up_listener()

func _process(_delta: float) -> void:
	if listener.get_available_packet_count() > 0:
		var server_ip = listener.get_packet_ip()
		var server_port = listener.get_packet_port()
		var bytes = listener.get_packet()
		var data = bytes.get_string_from_utf8()
		var room_info_from_data = JSON.parse_string(data)
		
		print("Server IP: " + server_ip + " Server Port: " + str(server_port) + " Room info: " + str(room_info_from_data))
		
		for i in $Panel/VBoxContainer/ScrollContainer/VBoxContainer.get_children():
			if i.name == room_info_from_data.name:
				update_server.emit(server_ip, server_port, room_info_from_data)
				i.get_node("IPLabel").text = server_ip
				i.get_node("PlayerCountLabel").text = str(int(room_info_from_data.playerCount))
				return
		var currentInfo = serverInfo.instantiate()
		currentInfo.name = room_info_from_data.name
		currentInfo.get_node("ServerNameLabel").text = room_info_from_data.name
		currentInfo.get_node("IPLabel").text = server_ip
		currentInfo.get_node("PlayerCountLabel").text = str(int(room_info_from_data.playerCount))
		$Panel/VBoxContainer/ScrollContainer/VBoxContainer.add_child(currentInfo)
		currentInfo.join_game.connect(join_by_ip)
		found_server.emit(server_ip, server_port, room_info_from_data)
		pass

func setup_up_listener():
	listener = PacketPeerUDP.new()
	var ok = listener.bind(listenPort)
	if ok == OK:
		print("Successfully bound to listen Port: " + str(listenPort) + "!")
	else:
		print("Failed to bind to listen Port")

func set_up_broadcast(server_name: String):
	room_info.name = server_name
	room_info.playerCount = MultiplayerPlayerManager.players.size()
	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address(broadcastAddress, listenPort)
	
	var ok = broadcaster.bind(broadcastPort)
	if ok == OK:
		print("Successfully bound to broadcast port " + str(broadcastPort) + " !")
	else:
		print("Failed to bind to Broadcast Port")
		
	broadcast_timer.start()
		
func clean_up():
	broadcast_timer.stop()
	listener.close()
	if broadcaster !=  null:
		broadcaster.close()

func _on_broadcast_timer_timeout() -> void:
	room_info.playerCount = MultiplayerPlayerManager.players.size()
	var data = JSON.stringify(room_info)
	var packet = data.to_utf8_buffer()
	broadcaster.put_packet(packet)

func _exit_tree() -> void:
	clean_up()

func join_by_ip(ip):
	join_game.emit(ip)
