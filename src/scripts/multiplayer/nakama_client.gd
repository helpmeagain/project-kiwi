extends Node

@onready var ip_input = $ServerControl/VBoxContainer/IPContainer/IPLineEdit
@onready var server_control = $ServerControl
@onready var user_control = $UserControl

var button_pressed = 0

func _ready():
	#randomize()
	#ip_input.text = "127.0.0.1"
	ip_input.text = "192.168.1.1"
	user_control.profile_updated.connect(_on_profile_updated)
	user_control.start_game.connect(start_game)
	NakamaManager.socket_connected.connect(on_socket_connected)
	NakamaManager.socket_closed.connect(on_socket_closed)
	NakamaManager.socket_error.connect(on_socket_received_error)
	NakamaManager.notification_received.connect(_on_notification_received)

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

func _on_profile_updated(success: bool):
	if success && !NakamaManager.is_user_created:
		NakamaManager.is_user_created = true
		PopupManager.show_custom("Status", "Conta criada! Pronto para jogar!", Color.GREEN)

func start_game() -> void:
	get_tree().change_scene_to_file("res://src/scenes/gameplay/arcade-questions.tscn")

func _parse_ip_and_port(input_text: String, default_port: int = 7350) -> Dictionary:
	var parts = input_text.strip_edges().split(":")
	var ip = parts[0]
	var port = default_port
	if parts.size() > 1:
		port = int(parts[1])
	return { "ip": ip, "port": port }

func on_socket_connected():
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

func _on_start_button_pressed() -> void:
	button_pressed += 1
	if (button_pressed >= 10):
		start_game()

func _on_back_button_pressed() -> void:
	if NakamaManager.socket: NakamaManager.socket.close()
	get_tree().change_scene_to_file("res://src/scenes/menus/main-menu.tscn")

func _on_notification_received(notification_data : NakamaAPI.ApiNotification):
	var json = JSON.new()
	var error = json.parse(notification_data.content)
	
	if error == OK:
		var content = json.get_data()
		print("[DEBUG - NOTIFICATION] Message: ", content["message"])
		if content.has("message") and content["message"] == "Start game!":
			user_control.start_game_countdown()
	else:
		push_error("Erro ao parsear notificação: ", json.get_error_message())
