extends Control

var button_pressed = 0

func _on_singleplayer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/singleplayer-menu.tscn")

func _on_multiplayer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/multiplayer-menu.tscn")

func _on_about_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/about-menu.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_easter_egg_button_pressed() -> void:
	button_pressed += 1
	if (button_pressed >= 10):
		$LabelAndButtonsContainer/ButtonsContainer/MultiplayerButton.disabled = false
		$LabelAndButtonsContainer/ButtonsContainer/MultiplayerButton.mouse_default_cursor_shape = 2
