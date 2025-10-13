extends Control

var button_pressed = 0

func _ready() -> void:
	if OS.has_feature("web"):
		$LabelAndButtonsContainer/ButtonsContainer/ExitButton.visible = false
		$LabelAndButtonsContainer/ButtonsContainer/ExitButton.disabled = true
		
func _on_singleplayer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/singleplayer-menu.tscn")

func _on_multiplayer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/nakama-menu.tscn")

func _on_about_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/about-menu.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_nakama_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/nakama-menu.tscn")
