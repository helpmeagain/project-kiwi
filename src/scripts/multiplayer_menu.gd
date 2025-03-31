extends Control

@export var address = "127.0.0.1"
@export var port = 8910
var peer

func _ready() -> void:
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(player_connected_to_server)
	multiplayer.connection_failed.connect(player_connection_failed)
	
	$ServerBrowser.join_game.connect(join_by_ip)

func player_connected(id):
	print("Player connected: " + str(id))

func player_disconnected(id):
	print("Player disconnected: " + str(id))
	MultiplayerPlayerManager.players.erase(id)
	
func player_connected_to_server():
	print("Connected to server")
	send_player_information.rpc_id(1, $NameInputContainer/NameLineEdit.text, multiplayer.get_unique_id())
	
func player_connection_failed():
	print("Connection failed")

@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://src/scenes/questions.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

@rpc("any_peer")
func send_player_information(player_name, id):
	if (!MultiplayerPlayerManager.players.has(id)):
		MultiplayerPlayerManager.players[id] = {
			"name": player_name,
			"id": id,
			"score": 0
		}
		print("[DEBUG] Jogador registrado: ", player_name, "; ID: ", id)
	if multiplayer.is_server():
		for i in MultiplayerPlayerManager.players:
			send_player_information.rpc(MultiplayerPlayerManager.players[i].name, i)
			
func show_error(message: String):
	$Window.show()
	$Window/HBoxContainer/WindowLabel.text = (message)
	print("[DEBUG] " + message)

func _on_host_button_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 45)
	if error != OK:
		show_error("Cannot host: " + error_string(error))
		return
	# peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	send_player_information("Teacher", multiplayer.get_unique_id())
	$ServerBrowser.set_up_broadcast($NameInputContainer/NameLineEdit.text + "'s server")
	print("Waiting for players...")

func _on_join_button_pressed() -> void:
	var player_name = $NameInputContainer/NameLineEdit.text
	if player_name == "":
		show_error("Invalid name: Empty" )
		return
		
	join_by_ip(address)

func join_by_ip(ip):
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error != OK:
		show_error("Cannot join: " + error_string(error))
		return
	#peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Joined game!")

func _on_start_button_pressed() -> void:
	if multiplayer.is_server():
		start_game.rpc()
	else:
		show_error("Only host can start the game")

func _on_window_close_requested() -> void:
	$Window.hide()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main-menu.tscn")

func _on_debug_add_players_button_pressed() -> void:
	MultiplayerPlayerManager.players[MultiplayerPlayerManager.players.size() + 1] ={
			"name" : "test",
			"id" : 1,
			"score": 0
		}
	pass
