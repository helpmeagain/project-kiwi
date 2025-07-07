class_name UIManager
extends Node

const BACKGROUNDS = [
	"res://src/assets/backgrounds/dining_kitchen.jpg",
	"res://src/assets/backgrounds/old_school.png",
	"res://src/assets/backgrounds/outdoor_stairs.png",
	"res://src/assets/backgrounds/single_bedroom.jpg",
	"res://src/assets/backgrounds/train_day.png"
]

# Referências
var parent: Control
var countdown_value: int = 0

func _init(parent_node: Control) -> void:
	parent = parent_node

func initialize_ui() -> void:
	parent.get_node("PowerUpControl").hide()
	update_question_count(0)
	update_score_display(0)
	update_powerup_icons()
	parent.get_node("FinalLabel").hide()
	parent.get_node("Player-score").hide()
	parent.get_node("WrongAnswer").hide()
	if parent.multiplayer_manager.is_multiplayer():
		parent.get_node("ShowPlayersButton").show()
	else:
		parent.get_node("ShowPlayersButton").hide()

func update_ui_components(score: int, question_count: int) -> void:
	update_score_display(score)
	update_question_count(question_count)
	update_powerup_icons()

func update_score_display(score_value: int) -> void:
	parent.get_node("ScoreLabel").text = "Score = " + str(score_value)

func update_question_count(count: int) -> void:
	parent.get_node("QuestionCountLabel").text = str(count) + "/" + str(parent.exercise_manager.MAX_QUESTIONS)

func update_timer_display(time_left: float) -> void:
	parent.get_node("TimerLabel").text = str(int(time_left)) + "s"

func update_powerup_icons() -> void:
	var icon1 = parent.get_node("PowerUpIconsControl/HBoxContainer/PowerUpIcon1")
	var icon2 = parent.get_node("PowerUpIconsControl/HBoxContainer/PowerUpIcon2")
	
	icon1.visible = parent.power_up_manager.double_points_active
	icon2.visible = parent.power_up_manager.extra_life_active

func show_final_screen(final_score: int) -> void:
	var final_label = parent.get_node("FinalLabel")
	final_label.text = "Game over! Score: " + str(final_score)
	final_label.show()
	parent.get_node("FinalButton").show()
	
	parent.get_node("ScoreLabel").hide()
	parent.get_node("PowerUpIconsControl").hide()
	parent.get_node("QuestionCountLabel").hide()
	parent.get_node("ShowPlayersButton").hide()
	parent.get_node("TimerLabel").hide()
	
	if parent.multiplayer_manager.is_multiplayer():
		var player_score = parent.get_node("Player-score")
		player_score.position = Vector2(450, 200)
		player_score.show()
	
	if parent.exercise_manager.current_question:
		parent.exercise_manager.current_question.queue_free()

func show_powerup_screen() -> void:
	parent.power_up_manager.extra_life_used = false
	parent.get_node("PowerUpControl").show()

func hide_powerup_screen() -> void:
	parent.get_node("PowerUpControl").hide()
	
func show_pop_up(is_correct_answer: bool, title: String, subtitle: String) -> void:
	if (is_correct_answer):
		parent.get_node("WrongAnswer/WrongPanel/VBoxContainer/TitleLabel").add_theme_color_override("font_shadow_color", Color(0,255,0,40))
	else:
		parent.get_node("WrongAnswer/WrongPanel/VBoxContainer/TitleLabel").add_theme_color_override("font_shadow_color", Color(255,0,0,40))
	parent.get_node("WrongAnswer/WrongPanel/VBoxContainer/TitleLabel").text = title
	parent.get_node("WrongAnswer/WrongPanel/VBoxContainer/Subtitle").text = subtitle
	parent.get_node("WrongAnswer").show()
	
func show_wrong_answer(correct_answer: String) -> void:
	show_pop_up(false, "Wrong answer!", "Correct answer was: " + correct_answer)

func show_timeout_message(correct_answer: String) -> void:
	show_pop_up(false, "Time's Up!", "Correct answer was: " + correct_answer)
	
func show_congratulations_answer(points: int, answer: String) -> void:
	show_pop_up(true, "Correct answer!", "The answer was: " + answer + "\n +" + str(points) + " points")
	
func hide_wrong_answer() -> void:
	parent.get_node("WrongAnswer").hide()

func toggle_player_score_display() -> void:
	var player_score = parent.get_node("Player-score")
	player_score.visible = not player_score.visible
	
func show_searching_message() -> void:
	parent.get_node("MultiplayerUIControl/MatchmakingLabel").text = "Procurando outro jogador..."
	parent.get_node("MultiplayerUIControl/LoadingSprite").play("Loading")
	parent.get_node("MultiplayerUIControl/LoadingSprite").show()
	parent.get_node("MultiplayerUIControl").show()

func show_countdown_message(message: String) -> void:
	parent.get_node("MultiplayerUIControl/MatchmakingLabel").text = message
	parent.get_node("MultiplayerUIControl/LoadingSprite").stop()
	parent.get_node("MultiplayerUIControl/LoadingSprite").hide()
	parent.get_node("MultiplayerUIControl").show()

func hide_matchmaking_message() -> void:
	parent.get_node("MultiplayerUIControl").hide()

func start_countdown() -> void:
	countdown_value = 3
	show_countdown_message("Parceiro encontrado! Iniciando em " + str(countdown_value) + "...")
	
	var timer = parent.get_node("MultiplayerUIControl/MatchmakingTimer")
	if timer.timeout.is_connected(_update_countdown):
		timer.timeout.disconnect(_update_countdown)
	
	timer.timeout.connect(_update_countdown)
	timer.wait_time = 1.0
	timer.start()

func _update_countdown() -> void:
	countdown_value -= 1
	
	if countdown_value > 0:
		show_countdown_message("Parceiro encontrado! Iniciando em " + str(countdown_value) + "...")
	else:
		var timer = parent.get_node("MultiplayerUIControl/MatchmakingTimer")
		timer.stop()
		hide_matchmaking_message()
		timer.timeout.disconnect(_update_countdown)

func set_random_background(transition_type: String = "fade") -> void:
	var random_path = BACKGROUNDS[randi() % BACKGROUNDS.size()]
	var new_texture: Texture2D = load(random_path)

	if new_texture:
		parent.get_node("BackgroundControl/ImageBackground").change_background(new_texture, transition_type)
	else:
		push_error("Failed to load background texture: " + random_path)
