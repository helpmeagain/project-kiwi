extends Control

func _ready() -> void:
	$ArcadeHighScoreLabel.text += str(SaveManager.get_highscore(false))

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/main-menu.tscn")

func _on_history_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/gameplay/visual-novel.tscn")

func _on_arcade_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/gameplay/arcade-questions.tscn")
