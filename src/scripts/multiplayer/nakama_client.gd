extends Node

var session : NakamaSession
var client : NakamaClient
var socket : NakamaSocket
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

func _on_back_button_pressed() -> void:
	if socket: socket.close()
	get_tree().change_scene_to_file("res://src/scenes/menus/main-menu.tscn")

func onSocketConnected():
	print("Socket connected")
	server_connected = true
	server_control.visible = false
	user_control.visible = true
	user_control.setup(client, session, is_user_created)
	PopupManager.show_success("Conectado ao servidor!")

func onSocketClosed():
	print("Socket closed")
	server_connected = false
	server_control.visible = true
	user_control.visible = false
	if is_inside_tree():
		PopupManager.show_warning("Conexão fechada")

func onSocketReceivedError(err):
	if is_inside_tree():
		PopupManager.show_error("ERRO: " + str(err))
	server_connected = false
