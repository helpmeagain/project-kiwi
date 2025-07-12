extends Control

var nakama_client: NakamaClient
var nakama_session: NakamaSession
var is_user_created: bool

@onready var username_input = $VBoxContainer/NameInputContainer/NameLabel
@onready var user_button = $VBoxContainer/UserButton
@onready var loading_sprite = $LoadingSprite
@onready var wait_label = $WaitLabel

signal profile_updated(success: bool)

func _ready():
	loading_sprite.hide()
	wait_label.hide()

func setup(client: NakamaClient, session: NakamaSession, user_created: bool) -> void:
	nakama_client = client
	nakama_session = session
	is_user_created = user_created
	update_button_text()

func update_button_text() -> void:
	user_button.text = "Update user" if is_user_created else "Create user"

func update_user_info(username_updated: String) -> void:
	PopupManager.show_custom("Perfil", "Atualizando perfil...", Color.LIGHT_BLUE)
	
	var result = await nakama_client.update_account_async(
		nakama_session,
		username_updated, # username
		null, # display name
		"",  # avatar url
		"pt", # language
		"br", # location
		"est" # timezone
	)
	
	if result.is_exception():
		var error = result.get_exception().message
		PopupManager.show_error("Erro ao atualizar: " + error)
		profile_updated.emit(false)
		return
	
	PopupManager.show_custom("Perfil", "Perfil atualizado!", Color.GREEN)
	profile_updated.emit(true)

func _on_user_button_pressed() -> void:
	if username_input.text.strip_edges() == "":
		PopupManager.show_warning("Digite um nome de usuário!")
		return
	
	await update_user_info(username_input.text)
	
	if !is_user_created:	
		is_user_created = true
		update_button_text()
	else:
		#var user_data = await client.get_account_async(session)
		#print(user_data.user.username)
		pass
	
	loading_sprite.play()
	loading_sprite.show()
	wait_label.show()
