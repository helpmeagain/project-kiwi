extends Control

const EXERCISE_CONFIG = {
	"fill_in_blank": "res://src/scenes/exercises/fill-in-the-blank.tscn",
	"listen_then_type": "res://src/scenes/exercises/listen-then-type.tscn",
	"type_translation": "res://src/scenes/exercises/type-the-sentence.tscn"
}
const SCORE_TEXT = "Score = "
const MAX_QUESTIONS = 7
const POWERUP_INTERVAL := 3
const FILL_IN_BLANK_TIME = 5
const DEFAULT_TIME = 10 

var current_question: Node
var score: int
var question_count: int
var timeout_occurred := false
var current_exercise_type: String

var double_points_active := false
var extra_life_active := false
var extra_life_used := false

func _ready() -> void:
	score = 0
	question_count = 0
	$PowerUpControl.hide()
	$QuestionCountLabel.text = str(question_count) + "/" + str(MAX_QUESTIONS)
	$ScoreLabel.text = SCORE_TEXT + str(score)
	update_powerup_icons()
	load_random_question()
	
func _process(_delta):
	$TimerLabel.text = str(int($Timer.time_left)) + "s"

func load_random_question() -> void:
	if question_count >= MAX_QUESTIONS:
		show_final_screen()
		return
	
	if current_question:
		current_question.queue_free()
	
	var exercise_keys = EXERCISE_CONFIG.keys()
	var random_key = exercise_keys[randi() % exercise_keys.size()]
	current_exercise_type = random_key
	var config = EXERCISE_CONFIG[random_key]

	var scene = load(config).instantiate()
	scene.initialize()
	$QuestionsContainer.add_child(scene)
	
	current_question = scene
	question_count += 1
	$QuestionCountLabel.text = str(question_count) + "/" + str(MAX_QUESTIONS)
	set_random_background()
	timeout_occurred = false
	if current_exercise_type == "fill_in_blank":
		$Timer.wait_time = FILL_IN_BLANK_TIME
	else:
		$Timer.wait_time = DEFAULT_TIME
	$Timer.start()

	if current_question.has_signal("answer_correct"):
		current_question.connect("answer_correct", _on_answer_correct)
	if current_question.has_signal("answer_wrong"):
		current_question.connect("answer_wrong", _on_answer_wrong)

func set_random_background(transition_type: String = "fade") -> void:
	var dir = DirAccess.open("res://src/assets/backgrounds/")
	if dir == null:
		push_error("Failed to open backgrounds directory.")
		return

	var files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() in ["png", "jpg", "jpeg"]:
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	if files.size() == 0:
		push_error("No background images found in directory.")
		return

	var random_file = files[randi() % files.size()]
	var bg_path = "res://src/assets/backgrounds/" + random_file
	var new_texture: Texture2D = load(bg_path)

	if new_texture:
		$BackgroundControl/ImageBackground.change_background(new_texture, transition_type)
	else:
		push_error("Failed to load background texture: " + bg_path)

func show_final_screen() -> void:
	$FinalLabel.text = "Game over! Score: " + str(score)
	$FinalLabel.show()
	$ScoreLabel.hide()
	$PowerUpIconsControl.hide()
	$QuestionCountLabel.hide()
	$ShowPlayersButton.hide()
	$"Player-score".set_position(Vector2(450, 200))
	$"Player-score".show()
	if current_question:
		current_question.queue_free()

func _on_answer_correct() -> void:
	if timeout_occurred:
		return
		
	$Timer.stop()
	score += 2 if double_points_active else 1
	double_points_active = false
	update_powerup_icons()

	if multiplayer.is_server():
		MultiplayerPlayerManager.players[multiplayer.get_unique_id()]["score"] = score
		MultiplayerPlayerManager.update_player_score.rpc(multiplayer.get_unique_id(), score)
	else:
		MultiplayerPlayerManager.request_update_score.rpc_id(1, multiplayer.get_unique_id(), score)

	update_score_display()
	_next_step_after_answer()

func _on_answer_wrong() -> void:
	if timeout_occurred:
		return
		
	$Timer.stop()
	if extra_life_active and not extra_life_used:
		extra_life_used = true
		extra_life_active = false
		update_powerup_icons()
		return
	update_score_display()

	var qd: Dictionary = current_question.current_question

	var respostas: Array = []
	if qd.has("correct_answers"):
		respostas = qd.correct_answers
	elif qd.has("correct_answer"):
		respostas = [ qd.correct_answer ]

	var certa: String = respostas[0] if respostas.size() > 0 else "—"

	$WrongAnswer/WrongPanel/VBoxContainer/Subtitle.text = certa
	$WrongAnswer.show()

func _next_step_after_answer() -> void:
	if question_count >= MAX_QUESTIONS:
		show_final_screen()
		return

	if question_count % POWERUP_INTERVAL == 0:
		show_powerup_screen()
	else:
		load_random_question()

func update_score_display() -> void:
	$ScoreLabel.text = SCORE_TEXT + str(score)

func _on_show_players_button_pressed() -> void:
	$"Player-score".visible = not $"Player-score".visible

func show_powerup_screen() -> void:
	extra_life_used = false
	$PowerUpControl.show()

func _on_powerup_double() -> void:
	double_points_active = true
	hide_powerup_screen()
	update_powerup_icons()
	load_random_question()

func _on_powerup_life() -> void:
	extra_life_active = true
	hide_powerup_screen()
	update_powerup_icons()
	load_random_question()

func hide_powerup_screen() -> void:
	$PowerUpControl.hide()
	
func update_powerup_icons() -> void:
	$PowerUpIconsControl/HBoxContainer/PowerUpIcon1.visible = double_points_active
	$PowerUpIconsControl/HBoxContainer/PowerUpIcon2.visible = extra_life_active


func _on_wrong_panel_button_pressed() -> void:
	$WrongAnswer.hide()
	_next_step_after_answer()

func _on_timer_timeout() -> void:
	timeout_occurred = true
	$TimerLabel.text = "0s"
	$Timer.stop()
	
	if current_question:
		$WrongAnswer/WrongPanel/VBoxContainer/TitleLabel.text = "Time's Up!"
		
		var qd: Dictionary = current_question.current_question
		var respostas: Array = []
		if qd.has("correct_answers"):
			respostas = qd.correct_answers
		elif qd.has("correct_answer"):
			respostas = [qd.correct_answer]

		var certa: String = respostas[0] if respostas.size() > 0 else "—"
		$WrongAnswer/WrongPanel/VBoxContainer/Subtitle.text = "Correct answer: " + certa
		
		$WrongAnswer.show()
	else:
		_next_step_after_answer()
