extends Control

func _on_singleplayer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/gameplay/visual-novel.tscn")

func _on_multiplayer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/multiplayer-menu.tscn")

func _on_about_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/about-menu.tscn")

func _on_how_to_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/gameplay/arcade-questions.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
