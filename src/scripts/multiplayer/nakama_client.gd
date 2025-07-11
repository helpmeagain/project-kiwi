extends Node

var session : NakamaSession
var client : NakamaClient
var socket : NakamaSocket

@onready var username = $InputContainer/NameInputContainer/NameLineEdit
@onready var ip_input = $InputContainer/IPContainer/IPLineEdit
@onready var status_label = $StatusLabel

func _ready():
	ip_input.text = "192.168.1.1:7350"
	update_status("Desconectado", Color.RED)

func onSocketConnected():
	print("Socket connected")
	
func onSocketClosed():
	print("Socket closed")
	
func onSocketReceviedError(err):
	print("Socket Recived error: " + str(err))
	
func onMatchPresence(presence: NakamaRTAPI.MatchPresenceEvent):
	print(presence)

func onSocketMatchState(state : NakamaRTAPI.MatchData):
	print(state)
	
func onSocketReceivedError(err):
	update_status("ERRO: " + str(err), Color.RED)


func updateUserInfo(username_updated, avaterurl = "", language = "pt", location = "br", timezone = "est"):
	update_status("Atualizando perfil...", Color.LIGHT_BLUE)
	
	var result = await client.update_account_async(
		session,
		username_updated,
		null,
		avaterurl,
		language,
		location,
		timezone
	)
	
	if result.is_exception():
		var error = result.get_exception().message
		update_status("Erro ao atualizar: " + error, Color.RED)
		return false
	
	update_status("Perfil atualizado!", Color.GREEN)
	return true

#func _on_submit_button_pressed() -> void:
	##var deviceId = OS.get_unique_id()
	#session = await client.authenticate_email_async(username.text + "@email.com", "password")
	##session = await client.authenticate_device_async(deviceId, username.text, true)
	#socket = Nakama.create_socket_from(client)
	#
	#await socket.connect_async(session)
	#socket.connected.connect(onSocketConnected)
	#socket.closed.connect(onSocketClosed)
	#socket.received_error.connect(onSocketReceviedError)
	#socket.received_match_presence.connect(onMatchPresence)
	#socket.received_error.connect(onSocketMatchState)
	#updateUserInfo(username.text)

func _on_submit_button_pressed() -> void:
	# Validação de entrada
	if username.text.strip_edges() == "":
		update_status("Digite um nome de usuário", Color.YELLOW)
		return
	
	if ip_input.text.strip_edges() == "":
		update_status("Digite um endereço IP", Color.YELLOW)
		return
	
	update_status("Conectando...", Color.LIGHT_BLUE)
	
	# Parse do IP e porta
	var parts = ip_input.text.split(":")
	var ip = parts[0]
	var port = 7350
	if parts.size() > 1:
		port = int(parts[1])
	
	client = Nakama.create_client("defaultkey", ip, port, "http")
	var email = username.text + "@email.com"
	session = await client.authenticate_email_async(email, "password")
	
	if session.is_exception():
		var error = session.get_exception().message
		update_status("Falha na autenticação: " + error, Color.RED)
		return
	
	# Cria e conecta socket
	socket = Nakama.create_socket_from(client)
	
	# Conecta sinais antes da conexão
	socket.connected.connect(onSocketConnected)
	socket.closed.connect(onSocketClosed)
	socket.received_error.connect(onSocketReceivedError)
	socket.received_match_presence.connect(onMatchPresence)
	socket.received_match_state.connect(onSocketMatchState)
	var connection = await socket.connect_async(session)
	
	if connection.is_exception():
		var error = connection.get_exception().message
		update_status("Falha na conexão: " + error, Color.RED)
		return
	
	update_status("Conectado ao socket!", Color.GREEN)
	update_status("Configurando perfil...", Color.LIGHT_BLUE)
	var profile_updated = await updateUserInfo(username.text)
	
	if profile_updated:
		update_status("Pronto para jogar!", Color.GREEN)
	else:
		update_status("Conectado, mas falha ao atualizar perfil", Color.YELLOW)

func _on_update_button_pressed() -> void:
	updateUserInfo(username.text)

#func _on_store_button_pressed() -> void:
	#var saveGame = {
		#"name" : username.text,
		#"items" : [{
			#"id" : 1,
			#"name" : "gun",
			#"ammo" : 10
		#},
		#{
			#"id" : 2,
			#"name" : "sword",
			#"ammo" : 0
		#}],
		#"level" : 10
	#}
	#var data = JSON.stringify(saveGame)
	#var result = await client.write_storage_objects_async(session, [
		#NakamaWriteStorageObject.new("saves", "savegame", 1, 1, data , "")
	#])
	#
	#if result.is_exception():
		#print("error" + str(result))
		#return
	#print("Stored data successfully!")
#
#func _on_get_button_pressed() -> void:
	#var result = await client.read_storage_objects_async(session, [
		#NakamaStorageObjectId.new("saves", "savegame", session.user_id)
	#])
	#
	#if result.is_exception():
		#print("error" + str(result))
		#return
	#for i in result.objects:
		#print(i.value)

func update_status(message: String, color: Color = Color.WHITE):
	status_label.text = message
	status_label.modulate = color


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/main-menu.tscn")
