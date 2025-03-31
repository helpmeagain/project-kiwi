extends HBoxContainer

signal join_game(ip)

func _on_button_pressed() -> void:
	join_game.emit($IPLabel.text)
