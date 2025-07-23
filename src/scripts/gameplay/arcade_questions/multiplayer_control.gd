class_name MultiplayerControl
extends Control

signal partner_found()
signal data_received(data)

var is_receiver_connected := false

#func _ready() -> void:
	#if is_multiplayer_session():
		#NakamaManager.socket.received_match_state.connect(recive_data_from_nakama)

func is_multiplayer_session() -> bool:
	return NakamaManager.is_server_connected()

func enter_matchmaking() -> void:
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
	
	print(ticket)
	if ticket.is_exception():
		var error = ticket.get_exception().message
		
		PopupManager.show_error("Erro no matchmaking: " + error)
		return
	
	print("DEBUG - TENANDO ENCONTRAR")
	NakamaManager.socket.received_matchmaker_matched.connect(_on_matchmaker_matched)
	
func _on_matchmaker_matched(matchmaker_matched : NakamaRTAPI.MatchmakerMatched):
	var joinedMatch = await NakamaManager.socket.join_matched_async(matchmaker_matched)
	
	if joinedMatch.is_exception():
		var error = joinedMatch.get_exception().message
		PopupManager.show_error("Erro ao entrar na partida: " + error)
		return
	
	NakamaManager.current_match = joinedMatch
	print("Entrou na partida: ", NakamaManager.current_match.match_id)
	if !is_receiver_connected:
		NakamaManager.socket.received_match_state.connect(recive_data_from_nakama)
		is_receiver_connected = true
	emit_signal("partner_found")
	NakamaManager.socket.received_matchmaker_matched.disconnect(_on_matchmaker_matched)
	
func send_data_through_nakama(data) -> void:
	NakamaManager.socket.send_match_state_async(NakamaManager.current_match.match_id, 1, JSON.stringify(data))

func recive_data_from_nakama(state : NakamaRTAPI.MatchData) -> void:
	var data = JSON.parse_string(state.data)
	emit_signal("data_received", data)

func leave_match() -> void:
	# TODO melhorar isso
	if NakamaManager.current_match != null:
		var match_id = NakamaManager.current_match.match_id
		NakamaManager.socket.leave_match_async(match_id)
		NakamaManager.current_match = null
		if is_receiver_connected:
			NakamaManager.socket.received_match_state.disconnect(recive_data_from_nakama)
			is_receiver_connected = false
		print("[NAKAMA DEBUG] SAIU DA PARTIDA: " + match_id)
	else:
		print("Aviso: Tentativa de sair de uma partida inexistente")

func get_match_id() -> String:
	if NakamaManager.current_match:
		return NakamaManager.current_match.match_id
	return ""
