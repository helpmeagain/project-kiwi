class_name MultiplayerManager
extends Node

enum MatchmakingState { IDLE, WAITING, MATCHED }

var parent: Control
var matchmaking_state = MatchmakingState.IDLE
var current_partner: int = -1
var current_exercise_id: String = ""
var matchmaking_timer: Timer

static var server_waiting_players = {}
var active_pairs = []

func _init(parent_node: Control) -> void:
	parent = parent_node
	matchmaking_timer = Timer.new()
	matchmaking_timer.name = "MatchmakingTimer"
	matchmaking_timer.wait_time = 2.0
	matchmaking_timer.autostart = true
	matchmaking_timer.timeout.connect(_on_matchmaking_timer_timeout)
	add_child(matchmaking_timer)

func is_multiplayer() -> bool:
	var peer = multiplayer.multiplayer_peer
	if peer == null:
		return false
	if peer is ENetMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		return true
	return false

func enter_matchmaking() -> void:
	if not is_multiplayer():
		print("[DEBUG] Matchmaking falhou: não está no modo multiplayer")
		return
		
	matchmaking_state = MatchmakingState.WAITING
	current_exercise_id = "multiplayer_fill_" + str(Time.get_unix_time_from_system())
	parent.ui_manager.show_searching_message()
	
	if multiplayer.is_server():
		print("[DEBUG] Servidor tentando parear jogadores")
		add_to_waiting_queue.rpc(multiplayer.get_unique_id(), current_exercise_id)
		if (multiplayer.get_unique_id() == 1): server_waiting_players[multiplayer.get_unique_id()] = current_exercise_id
		try_match_players()
	else:
		print("[DEBUG] Cliente notificando servidor")
		notify_matchmaking.rpc_id(1, multiplayer.get_unique_id(), current_exercise_id)

@rpc("any_peer", "reliable")
func notify_matchmaking(player_id: int, exercise_id: String) -> void:
	if multiplayer.is_server():
		add_to_waiting_queue(player_id, exercise_id)
		try_match_players()

@rpc("authority", "reliable")
func add_to_waiting_queue(player_id: int, exercise_id: String) -> void:
	if multiplayer.is_server():
		server_waiting_players[player_id] = exercise_id

func try_match_players() -> void:
	if not multiplayer.is_server():
		return
	print("[DEBUG] Tentando parear jogadores. Jogadores na espera: ", server_waiting_players.size())
	
	var players = server_waiting_players.keys()
	if players.size() < 2:
		print("[SERVER] Not enough players to match")
		return
	
	var player1 = players[0]
	var player2 = players[1]
	active_pairs.append([player1, player2])
	var question_data = ExercisesBank.load_random_question("multiplayer_fill_in_the_blank.json")
	
	#print("[SERVER] Matching players: ", player1, " and ", player2, ". Question data: ", question_data)
	server_waiting_players.erase(player1)
	server_waiting_players.erase(player2)
	notify_match_found.rpc_id(player1, player2, question_data)
	notify_match_found.rpc_id(player2, player1, question_data)

@rpc("any_peer", "call_local", "reliable")
func notify_match_found(partner_id: int, question_data: Dictionary) -> void:
	current_partner = partner_id
	matchmaking_state = MatchmakingState.MATCHED
	parent.ui_manager.start_countdown()
	
	parent.get_tree().create_timer(3.0).timeout.connect(
		func(): parent.exercise_manager.load_multiplayer_exercise(current_partner, question_data)
	)

func _receive_answer_locally(player_id: int, answer: String) -> void:
	if multiplayer.is_server():
		_process_answer(player_id, answer)

func _process_answer(player_id: int, answer: String) -> void:
	print("[SERVER] Received answer from:", player_id, " answer:", answer)
	
	var partner_id = -1
	for pair in active_pairs:
		if pair[0] == player_id:
			partner_id = pair[1]
			break
		elif pair[1] == player_id:
			partner_id = pair[0]
			break
	
	if partner_id != -1:
		print("[SERVER] Forwarding to partner:", partner_id)
		
		if partner_id != player_id:
			if partner_id == 1:
				_forward_answer_locally(partner_id, player_id, answer)
			else:
				rpc_id(partner_id, "_forward_answer", partner_id, player_id, answer)
	else:
		print("[SERVER] No partner found for:", player_id)

@rpc("any_peer", "reliable")
func submit_answer(player_id: int, answer: String) -> void:
	if multiplayer.is_server():
		_process_answer(player_id, answer)

func _forward_answer_locally(target_id: int, sender_id: int, answer: String) -> void:
	if multiplayer.get_unique_id() == target_id:
		print("[HOST] Received partner answer locally")
		multiplayer.emit_signal("partner_answer_received", sender_id, answer)

@rpc("reliable")
func _forward_answer(target_id: int, sender_id: int, answer: String) -> void:
	if multiplayer.get_unique_id() == target_id:
		print("[CLIENT] Received partner answer via RPC")
		multiplayer.emit_signal("partner_answer_received", sender_id, answer)
		
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
		
func _on_matchmaking_timer_timeout():
	if multiplayer.is_server() and server_waiting_players.size() > 0:
		print("[SERVER] Periodic matchmaking attempt")
		try_match_players()
