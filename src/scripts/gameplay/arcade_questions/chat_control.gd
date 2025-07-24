class_name ChatControl
extends Control

signal send_message(message)

@onready var chat_messages = $VBoxContainer/ChatTextLabel
@onready var player_username_label = $VBoxContainer/HBoxContainer/PlayerLabel
@onready var message_input = $VBoxContainer/HBoxContainer/LineEdit

var user_types = [
	{'name': 'player', 'color': '#00abc7'},
	{'name': 'partner', 'color': '#ffffff'},
	{'name': 'system', 'color': '#ffdd8b'}
]

var user_type_index = 0
var player_username: String

func update_player_username(username: String) -> void:
	player_username = username
	player_username_label.text = '[' + player_username + ']'

func add_message(username: String, message: String, user_type: int) -> void:
	if (!chat_messages.text == ""): chat_messages.text += '\n'
	chat_messages.text += '[color=' + user_types[user_type]['color'] + ']'
	chat_messages.text += '[' + username + ']: '
	chat_messages.text += message
	chat_messages.text += '[/color]'

func clear_chat() -> void:
	chat_messages.text = ""
	self.hide()

func _on_line_edit_text_submitted(new_text: String) -> void:
	if message_input.text.strip_edges() != "":
		add_message(player_username, new_text, 0)
		message_input.text = ""
		await get_tree().create_timer(0.03).timeout
		message_input.edit()
		emit_signal("send_message", new_text)
