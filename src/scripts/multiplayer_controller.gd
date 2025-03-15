extends Control

@export var address = "127.0.0.1"
@export var port = 8910
var peer

func _ready() -> void:
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(player_connected_to_server)
	multiplayer.connection_failed.connect(player_connected)

func player_connected(id):
	print("Player connected: " + str(id))

func player_disconnected(id):
	print("Player disconnected: " + str(id))
	
func player_connected_to_server():
	print("Connected to server")
	
func player_connection_failed():
	print("Connection failed")

@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://src/scenes/questions.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_host_button_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 45)
	if error != OK:
		print("Cannot host: " + error)
		return
	# peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for players...")

func _on_join_button_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	#peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Joined game!")

func _on_start_button_pressed() -> void:
	if multiplayer.is_server():
		start_game.rpc()
	else:
		print("Only host can start the game")
