class_name MultiplayerControl
extends Control

signal partner_found()
signal data_received(data)
signal leaderboard_updated(records)
signal player_disconnected
signal cancel_matchmaking

var is_receiver_connected := false
var current_ticket = null
const LEADERBOARD_ID = "global_leaderboard"
const DATA_TYPE = {
	USERNAME = "username",
	CONSIDER_ANSWER = "consider_answer",
	SUBMIT_ANSWER = "submit_answer",
	CHAT_MESSAGE = "chat_message",
	WRONG_ANSWER = "wrong_answer",
	SYSTEM_MSG = "system_msg"
}

func is_multiplayer_session() -> bool:
	return NakamaManager.is_server_connected()

func enter_matchmaking() -> void:
	current_ticket = null
	print("[DEBUB] STARTING MATCHAMAKING")
	var query = ""
	var min_players = 2
	var max_players = 2
	var string_properties = {}
	var numeric_properties = {}
	
	var ticket = await NakamaManager.socket.add_matchmaker_async(
		query, 
		min_players, 
		max_players,
		string_properties,
		numeric_properties
	)
	
	if ticket.is_exception():
		var error = ticket.get_exception().message
		PopupManager.show_error("Erro no matchmaking: " + error)
		return
	
	current_ticket = ticket
	$MatchmakingTimeoutTimer.start()
	NakamaManager.socket.received_matchmaker_matched.connect(_on_matchmaker_matched)
	
func _on_matchmaker_matched(matchmaker_matched : NakamaRTAPI.MatchmakerMatched):
	var joinedMatch = await NakamaManager.socket.join_matched_async(matchmaker_matched)
	
	if joinedMatch.is_exception():
		var error = joinedMatch.get_exception().message
		PopupManager.show_error("Erro ao entrar na partida: " + error)
		return
	
	$MatchmakingTimeoutTimer.stop()
	NakamaManager.current_match = joinedMatch
	if !is_receiver_connected:
		NakamaManager.socket.received_match_state.connect(recive_data_from_nakama)
		NakamaManager.socket.received_match_presence.connect(_on_match_presence_event)
		is_receiver_connected = true
	emit_signal("partner_found")
	NakamaManager.socket.received_matchmaker_matched.disconnect(_on_matchmaker_matched)

func _on_match_presence_event(event: NakamaRTAPI.MatchPresenceEvent):
	if event.leaves.size() ==  1:
		print("Player saiu! " + await NakamaManager.get_my_username() + " está sozinho")
		emit_signal("player_disconnected")

func leave_match() -> void:
	# TODO melhorar isso
	if NakamaManager.current_match != null:
		var match_id = NakamaManager.current_match.match_id
		NakamaManager.socket.leave_match_async(match_id)
		NakamaManager.current_match = null
		if is_receiver_connected:
			NakamaManager.socket.received_match_state.disconnect(recive_data_from_nakama)
			NakamaManager.socket.received_match_presence.disconnect(_on_match_presence_event)
			is_receiver_connected = false
		print("[NAKAMA DEBUG] SAIU DA PARTIDA: " + match_id)
	else:
		print("Aviso: Tentativa de sair de uma partida inexistente")

func get_match_id() -> String:
	if NakamaManager.current_match:
		return NakamaManager.current_match.match_id
	return ""

func update_leaderboard(score: int) -> void:
	if is_multiplayer_session():
		var record : NakamaAPI.ApiLeaderboardRecord = await NakamaManager.client.write_leaderboard_record_async(NakamaManager.session, LEADERBOARD_ID, score)
		if record.is_exception():
			print("An error occurred: %s" % record)
			return
		print("New record username %s and score %s" % [record.username, record.score])
	else:
		print("Not multiplayer. Not updating leadeboard")

func get_leaderboard_nakama() -> void:
	if is_multiplayer_session():
		var result : NakamaAPI.ApiLeaderboardRecordList = await NakamaManager.client.list_leaderboard_records_async(NakamaManager.session, LEADERBOARD_ID, null, null, 100)
		if result.is_exception():
			print("An error occurred: %s" % result)
			return
		emit_signal("leaderboard_updated", result.records)
	else:
		print("Not multiplayer. Not getting leadeboard")

func send_data(data_type: String, data_value) -> void:
	var data = {
		"type": data_type,
		"value": data_value
	}
	NakamaManager.socket.send_match_state_async(NakamaManager.current_match.match_id, 1, JSON.stringify(data))

func recive_data_from_nakama(state : NakamaRTAPI.MatchData) -> void:
	var data = JSON.parse_string(state.data)
	emit_signal("data_received", data)

func _on_matchmaking_timeout_timer_timeout() -> void:
	if current_ticket:
		await NakamaManager.socket.remove_matchmaker_async(current_ticket.ticket)
		current_ticket = null
		emit_signal("cancel_matchmaking")
	if NakamaManager.socket.received_matchmaker_matched.is_connected(_on_matchmaker_matched):
		NakamaManager.socket.received_matchmaker_matched.disconnect(_on_matchmaker_matched)
