extends Node

@onready var ip_input = $ServerControl/VBoxContainer/IPContainer/IPLineEdit
@onready var server_control = $ServerControl
@onready var user_control = $UserControl

func _ready():
	#randomize()
	#ip_input.text = "127.0.0.1"
	ip_input.text = "192.168.1.1"
	user_control.profile_updated.connect(_on_profile_updated)
	NakamaManager.socket_connected.connect(on_socket_connected)
	NakamaManager.socket_closed.connect(on_socket_closed)
	NakamaManager.socket_error.connect(on_socket_received_error)

func _on_connect_button_pressed() -> void:    
	if ip_input.text.strip_edges() == "":
		PopupManager.show_warning("Digite um endereço IP")
		return
	
	var connection_data = _parse_ip_and_port(ip_input.text)
	var ip = connection_data["ip"]
	var port = connection_data["port"]
	
	PopupManager.show_connecting()
	var success = await NakamaManager.connect_to_server(ip, port)
	if not success:
		PopupManager.show_error("Falha na conexão com o servidor")
		return
	
	#NakamaManager.socket.received_match_presence.connect(onMatchPresence)
	NakamaManager.socket.received_match_state.connect(onMatchState)

func _on_profile_updated(success: bool):
	if success && !NakamaManager.is_user_created:
		NakamaManager.is_user_created = true
		PopupManager.show_custom("Status", "Conta criada! Pronto para jogar!", Color.GREEN)

func start_matchmaking() -> void:
	print("Procurando oponente...")
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
	
	print("Matchmaking iniciado. Ticket: ", ticket)
	NakamaManager.socket.received_matchmaker_matched.connect(_on_matchmaker_matched)

func _on_matchmaker_matched(matchmaker_matched : NakamaRTAPI.MatchmakerMatched):
	var joinedMatch = await NakamaManager.socket.join_matched_async(matchmaker_matched)
	
	if joinedMatch.is_exception():
		var error = joinedMatch.get_exception().message
		PopupManager.show_error("Erro ao entrar na partida: " + error)
		return
	
	NakamaManager.current_match = joinedMatch
	print("Entrou na partida: ", NakamaManager.current_match.match_id)
	PopupManager.show_success("Oponente encontrado! Iniciando jogo...")
	#start_game()

func start_game() -> void:
	#print("Iniciando jogo na partida: ", NakamaManager.current_match.match_id)
	get_tree().change_scene_to_file("res://src/scenes/gameplay/arcade-questions.tscn")

func _parse_ip_and_port(input_text: String, default_port: int = 7350) -> Dictionary:
	var parts = input_text.strip_edges().split(":")
	var ip = parts[0]
	var port = default_port
	if parts.size() > 1:
		port = int(parts[1])
	return { "ip": ip, "port": port }

func on_socket_connected():
	print("[DEBUG] Socket connected - UI should update")
	server_control.visible = false
	user_control.visible = true
	user_control.setup(NakamaManager.client, NakamaManager.session, NakamaManager.is_user_created)
	if is_inside_tree():
		PopupManager.show_success("Conectado ao servidor!")

func on_socket_closed():
	print("[DEBUG - nakama_client.gd] Socket closed")
	server_control.visible = true
	user_control.visible = false
	if is_inside_tree():
		PopupManager.show_warning("Conexão fechada")

func on_socket_received_error(err):
	if is_inside_tree():
		PopupManager.show_error("ERRO: " + str(err))
	
#func onMatchPresence(presence : NakamaRTAPI.MatchPresenceEvent):
	#print("[DEBUG] PRESENCE:" + str(presence))

func onMatchState(state : NakamaRTAPI.MatchData):
	print("Data is : " + str(state.data))
	$UserControl/StateLabel.text = str(state.data)

func _on_ping_button_pressed() -> void:
	if NakamaManager.socket and NakamaManager.current_match:
		var data = {"hello" : "world"}
		NakamaManager.socket.send_match_state_async(NakamaManager.current_match.match_id, 1, JSON.stringify(data))

func _on_start_button_pressed() -> void:
	start_game()

func _on_back_button_pressed() -> void:
	if NakamaManager.socket: NakamaManager.socket.close()
	get_tree().change_scene_to_file("res://src/scenes/menus/main-menu.tscn")
