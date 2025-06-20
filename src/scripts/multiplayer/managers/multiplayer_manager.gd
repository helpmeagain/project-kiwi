class_name MultiplayerManager
extends Node

var parent: Control

func _init(parent_node: Control) -> void:
	parent = parent_node

func is_multiplayer() -> bool:
	var peer = multiplayer.multiplayer_peer
	if peer == null:
		return false
	if peer is ENetMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		return true
	return false

func update_score(score: int) -> void:
	if not is_multiplayer():
		return
		
	if multiplayer.is_server():
		MultiplayerPlayerManager.players[multiplayer.get_unique_id()]["score"] = score
		MultiplayerPlayerManager.update_player_score.rpc(multiplayer.get_unique_id(), score)
	else:
		MultiplayerPlayerManager.request_update_score.rpc_id(1, multiplayer.get_unique_id(), score)

func show_player_score() -> void:
	if is_multiplayer():
		parent.ui_manager.toggle_player_score_display()
