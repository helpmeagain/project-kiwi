extends Control

func _on_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/main-menu.tscn")

func _on_tengu_button_pressed() -> void:
	OS.shell_open("https://picrew.me/en/image_maker/1979868")

func _on_silver_button_pressed() -> void:
	OS.shell_open("https://poppyworks.itch.io/silver")

func _on_abbadon_button_pressed() -> void:
	OS.shell_open("https://caffinate.itch.io/abaddon")

func _on_edit_undo_button_pressed() -> void:
	OS.shell_open("https://www.dafont.com/edit-undo.font")

func _on_ruler_button_pressed() -> void:
	OS.shell_open("https://somepx.itch.io/free-font-ruler")

func _on_dialog_sound_button_pressed() -> void:
	OS.shell_open("https://alan-dalcastagne.itch.io/dialog-text-sound-effects")

func _on_gui_elements_button_pressed() -> void:
	OS.shell_open("https://mounirtohami.itch.io/pixel-art-gui-elements")

func _on_ui_assets_pack_button_pressed() -> void:
	OS.shell_open("https://srtoasty.itch.io/ui-assets-pack-2")

func _on_ui_cozy_button_pressed() -> void:
	OS.shell_open("https://toffeecraft.itch.io/ui-user-interface-pack-cozy-coffee")

func _on_lucid_button_pressed() -> void:
	OS.shell_open("https://leo-red.itch.io/lucid-icon-pack")

func _on_git_hub_button_pressed() -> void:
	OS.shell_open("https://github.com/helpmeagain")

func _on_repository_button_pressed() -> void:
	OS.shell_open("https://github.com/helpmeagain/project-kiwi")

func _on_anime_backgrounds_button_pressed() -> void:
	OS.shell_open("https://noranekogames.itch.io/yumebackground")

func _on_house_visual_novel_button_pressed() -> void:
	OS.shell_open("https://spiralatlas.itch.io/house-visual-novel-backgrounds")
