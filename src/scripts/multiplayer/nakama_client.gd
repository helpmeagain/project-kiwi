extends Node

var session : NakamaSession
var client : NakamaClient
var socket : NakamaSocket
var current_match : NakamaRTAPI.Match
var matchmaker_ticket : String
var server_connected := false
var is_user_created := false

@onready var ip_input = $ServerControl/VBoxContainer/IPContainer/IPLineEdit
@onready var server_control = $ServerControl
@onready var user_control = $UserControl

func _ready():
	ip_input.text = "127.0.0.1"
	#ip_input.text = "192.169.1.1"
	user_control.visible = false
	#PopupManager.instance().ok_pressed.connect(_on_popup_closed)
	user_control.profile_updated.connect(_on_profile_updated)
	#randomize()

func _on_connect_button_pressed() -> void:    
	if ip_input.text.strip_edges() == "":
		PopupManager.show_warning("Digite um endereço IP")
		return
	
	PopupManager.show_connecting()
	
	var parts = ip_input.text.split(":")
	var ip = parts[0]
	var port = 7350
	if parts.size() > 1:
		port = int(parts[1])
	
	client = Nakama.create_client("defaultkey", ip, port, "http")
	socket = Nakama.create_socket_from(client)
	socket.connected.connect(onSocketConnected)
	socket.closed.connect(onSocketClosed)
	socket.received_error.connect(onSocketReceivedError)
	
	session = await client.authenticate_device_async(OS.get_unique_id())
	#var random_number = randi() % 10001
	#var email = str(random_number) + "@email.com"
	#session = await client.authenticate_email_async(email, "password")
	if session.is_exception():
		var error = session.get_exception().message
		PopupManager.show_error("Falha na autenticação: " + error)
		return
	
	var connection = await socket.connect_async(session)
	if connection.is_exception():
		var error = connection.get_exception().message
		PopupManager.show_error("Falha na conexão: " + error)

func _on_profile_updated(success: bool):
	if success && !is_user_created:
		is_user_created = true
		PopupManager.show_custom("Status", "Conta criada! Pronto para jogar!", Color.GREEN)
		start_matchmaking()

func _on_back_button_pressed() -> void:
	if socket: socket.close()
	get_tree().change_scene_to_file("res://src/scenes/menus/main-menu.tscn")

func start_matchmaking() -> void:
	print("Procurando oponente...")
	var query = ""
	var min_players = 2
	var max_players = 2
	var string_properties = {}
	var numeric_properties = {}
	
	var ticket = await socket.add_matchmaker_async(
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
	socket.received_matchmaker_matched.connect(_on_matchmaker_matched)

func _on_matchmaker_matched(matchmaker_matched : NakamaRTAPI.MatchmakerMatched):
	var joinedMatch = await socket.join_matched_async(matchmaker_matched)
	
	if joinedMatch.is_exception():
		var error = joinedMatch.get_exception().message
		PopupManager.show_error("Erro ao entrar na partida: " + error)
		return
	
	current_match = joinedMatch
	print("Entrou na partida: ", current_match.match_id)
	PopupManager.show_success("Oponente encontrado! Iniciando jogo...")
	start_game()

func start_game() -> void:
	print("Iniciando jogo na partida: ", current_match.match_id)
	
func parse_ip_and_port(input_text: String, default_port: int = 7350) -> Dictionary:
	var parts = input_text.strip_edges().split(":")
	var ip = parts[0]
	var port = default_port
	if parts.size() > 1:
		port = int(parts[1])
	return { "ip": ip, "port": port }

func onSocketConnected():
	print("[DEBUG - nakama_client.gd] Socket connected")
	server_connected = true
	server_control.visible = false
	user_control.visible = true
	user_control.setup(client, session, is_user_created)
	PopupManager.show_success("Conectado ao servidor!")

func onSocketClosed():
	print("[DEBUG - nakama_client.gd] Socket closed")
	server_connected = false
	server_control.visible = true
	user_control.visible = false
	if is_inside_tree():
		PopupManager.show_warning("Conexão fechada")

func onSocketReceivedError(err):
	if is_inside_tree():
		PopupManager.show_error("ERRO: " + str(err))
	server_connected = false
