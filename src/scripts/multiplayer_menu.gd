extends Control

@export var address = "127.0.0.1"
@export var port = 8910
@onready var players_container = $PlayerBrowser/Panel/VBoxContainer/ScrollContainer/VBoxContainer
var peer

func _ready() -> void:
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(player_connected_to_server)
	multiplayer.connection_failed.connect(player_connection_failed)
	
	$ServerBrowser.join_game.connect(join_by_ip)

func player_connected(id):
	print("Player connected: " + str(id))
	update_player_list()

func player_disconnected(id):
	print("Player disconnected: " + str(id))
	MultiplayerPlayerManager.players.erase(id)
	update_player_list()
	
func player_connected_to_server():
	print("Connected to server")
	send_player_information.rpc_id(1, $NameInputContainer/NameLineEdit.text, multiplayer.get_unique_id())
	
func player_connection_failed():
	print("Connection failed")

@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://src/scenes/multiplayer/questions.tscn").instantiate()
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
		update_player_list()
		print("[DEBUG] Jogador registrado: ", player_name, "; ID: ", id)
	if multiplayer.is_server():
		for i in MultiplayerPlayerManager.players:
			send_player_information.rpc(MultiplayerPlayerManager.players[i].name, i)
			
func show_error(message: String):
	$Window.show()
	$Window/HBoxContainer/WindowLabel.text = (message)
	print("[DEBUG] " + message)

func _on_host_button_pressed() -> void:
	$PlayerBrowser.show()
	$NameInputContainer.show()
	$NameInputContainer/HostButton.show()
	$StartButton.show()
	$CloseButton.show()

func _on_join_button_pressed() -> void:
	$ServerBrowser.show()
	$NameInputContainer.show()
	$CloseButton.show()

func join_by_ip(ip):
	var player_name = $NameInputContainer/NameLineEdit.text
	if player_name == "":
		show_error("Invalid name: Empty" )
		return
		
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
	if peer:
		if multiplayer.is_server():
			peer.close()
		else:
			multiplayer.multiplayer_peer = null
	
	MultiplayerPlayerManager.players.clear()
	get_tree().change_scene_to_file("res://src/scenes/main-menu.tscn")

func _on_debug_add_players_button_pressed() -> void:
	MultiplayerPlayerManager.players[MultiplayerPlayerManager.players.size() + 1] ={
			"name" : "test",
			"id" : 1,
			"score": 0
		}
	pass

func _on_create_room_button_pressed() -> void:
	var host_name = $NameInputContainer/NameLineEdit.text
	if host_name == "":
		show_error("Invalid name: Empty" )
		return
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 45)
	if error != OK:
		show_error("Cannot host: " + error_string(error))
		return
	# peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	send_player_information("Teacher", multiplayer.get_unique_id())
	$ServerBrowser.set_up_broadcast($NameInputContainer/NameLineEdit.text + "'s server")
	$StartButton.show()
	print("Waiting for players...")

func _on_close_button_pressed() -> void:
	show_error("Not implemented")
	

func update_player_list():
	for child in players_container.get_children():
		child.queue_free()
	
	for player_id in MultiplayerPlayerManager.players:
		var player = MultiplayerPlayerManager.players[player_id]
		var new_label = Label.new()
		new_label.text = player["name"]
		new_label.add_theme_font_size_override("font_size", 18)
		new_label.theme = theme
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		players_container.add_child(new_label)
