extends Node

var players = {}
signal scores_updated

@rpc("any_peer", "reliable")
func request_update_score(player_id, new_score):
	if multiplayer.is_server():
		if players.has(player_id):
			players[player_id]["score"] = new_score
			update_player_score.rpc(player_id, new_score)

@rpc("authority", "call_local", "reliable")
func update_player_score(player_id, new_score):
	if players.has(player_id):
		players[player_id]["score"] = new_score
	emit_signal("scores_updated")
