extends Control

@onready var ui_elements: UIControl = $UIElements
@onready var power_up: Control = $PowerUpSelection
@onready var background: BackgroundImage = $BackgroundImage
@onready var exercises_control: ExercisesControl = $ExercisesControl
@onready var multiplayer_control: MultiplayerControl = $MultiplayerControl
@onready var exercises_timer: Timer = $ExerciseTimer
@onready var player_score = $PlayerScore
@onready var chat_control: ChatControl = $ChatControl

@export var score: int = 0
@export var question_count: int = 0
@export var max_questions = 5
@export var power_up_interval = 3
@export var fill_in_the_blank_timer: float = 15.0
@export var type_translation_timer: float = 30.0
@export var vocabulary_timer: float = 15.0
@export var multiplayer_fill_timer: float = 60.0
var timeout_occurred: bool = false
var double_points_active: bool = false
var extra_life_active: bool = false
var partner_username: String
var partner_answer: String

# TODO tirar isso e achar uma maneira decente de fazer
var POWERUP_CHOOSED = false

func _ready() -> void:
	load_next_exercise()
	#try_restore_active_session()
	ui_elements.max_questions = max_questions
	ui_elements.update_all_ui_components(score, question_count, double_points_active, extra_life_active)
	ui_elements.start_multiplayer_exercise.connect(load_next_exercise)
	multiplayer_control.partner_found.connect(_on_partner_found)
	multiplayer_control.data_received.connect(_on_data_received)
	player_score.set_multiplayer_control(multiplayer_control)
	chat_control.connect("send_message", _on_send_chat_message)
	if (!multiplayer_control.is_multiplayer_session()):
		ui_elements.hide_leaderboard()
	else:
		multiplayer_control.update_leaderboard(score)

func _process(_delta) -> void:
	ui_elements.update_timer_label(exercises_timer.time_left)

func try_restore_active_session() -> bool:
	var saved_data = SaveManager.load_session(multiplayer_control.is_multiplayer_session())
	
	if saved_data["question_count"] > 0 && saved_data["question_count"] < max_questions:
		score = saved_data["score"]
		question_count = saved_data["question_count"]
		double_points_active = saved_data["double_points_active"]
		extra_life_active = saved_data["extra_life_active"]
		timeout_occurred = false
		return true
	return false

func _on_answer_correct(points: int = 1) -> void:
	if timeout_occurred: return
	exercises_timer.stop()
	
	var points_earned = points
	if double_points_active:
		points_earned = points * 2
		score += points_earned
		double_points_active = false
	else:
		score += points
		
	PopupManager.instance().ok_pressed.connect(_on_popup_button_pressed)
	PopupManager.show_congratulations_answer(exercises_control.get_correct_answer(), points_earned)
	ui_elements.update_all_ui_components(score, question_count, double_points_active, extra_life_active)
	multiplayer_control.update_leaderboard(score)
	chat_control.clear_chat()

func _on_multiplayer_partial_correct(player_answer: String, partner_answer_recived: String, is_player_correct: bool, points: int = 1) -> void:
	if timeout_occurred: return
	exercises_timer.stop()

	var points_earned = points
	if is_player_correct:
		if double_points_active:
			points_earned = points * 2
			score += points_earned
			double_points_active = false
		else:
			score += points
		
	PopupManager.instance().ok_pressed.connect(_on_popup_button_pressed)
	PopupManager.show_partial_answer(player_answer, partner_answer_recived, is_player_correct, points_earned)
	ui_elements.update_all_ui_components(score, question_count, double_points_active, extra_life_active)
	multiplayer_control.update_leaderboard(score)
	chat_control.clear_chat()

func _on_answer_wrong() -> void:
	if timeout_occurred: return
	if extra_life_active and !exercises_control.current_exercise.has_method("use_extra_life"):
		_try_use_extra_life()
		return
	
	exercises_timer.stop()
	PopupManager.instance().ok_pressed.connect(_on_popup_button_pressed)
	PopupManager.show_wrong_answer(exercises_control.get_correct_answer())
	ui_elements.update_all_ui_components(score, question_count, double_points_active, extra_life_active)
	multiplayer_control.update_leaderboard(score)
	chat_control.clear_chat()

func _on_timer_timeout() -> void:
	exercises_timer.stop()
	if extra_life_active and !exercises_control.current_exercise.has_method("use_extra_life"):
		_try_use_extra_life()
		return
	
	timeout_occurred = true
	multiplayer_control.update_leaderboard(score)
	if exercises_control.current_exercise != null:
		PopupManager.instance().ok_pressed.connect(_on_popup_button_pressed)
		PopupManager.show_timeout_message(exercises_control.get_correct_answer())
	else:
		next_step_after_answer()

func next_step_after_answer() -> void:
	# TODO verificar o fluxo melhor, em relação a power ups. Fazer com que o powerup volte aqui, mas sem ativar o powerup time
	var POWER_UP_SELECTION_TIME = question_count % power_up_interval == 0
	var MAX_QUESTION_REACHED = question_count >= max_questions
	var MULTIPLAYER_QUESTION_TIME = question_count % 2 == 1 && multiplayer_control.is_multiplayer_session()
	if MAX_QUESTION_REACHED:
		finish_game()
		return
	if POWER_UP_SELECTION_TIME and !POWERUP_CHOOSED:
		power_up.show()
		return
	if MULTIPLAYER_QUESTION_TIME:
		print("[DEBUB] START MATCHAMAKING")
		start_matchmaking()
		return
	POWERUP_CHOOSED = false
	_save_session()
	load_next_exercise()

func load_next_exercise() -> void:
	var MULTIPLAYER_QUESTION_TIME = question_count % 2 == 1 && multiplayer_control.is_multiplayer_session()
	question_count += 1
	timeout_occurred = false
	ui_elements.update_question_count(question_count)
	background.set_random_background()
	if MULTIPLAYER_QUESTION_TIME:
		var match_id = multiplayer_control.get_match_id()
		exercises_control.show()
		chat_control.show()
		exercises_control.load_multiplayer_question(match_id)
		exercises_control.current_exercise.connect("send_considering_answer", _on_considering_answer_multiplayer)
		exercises_control.current_exercise.connect("send_submit_answer", _on_submit_answer_multiplayer)
		exercises_control.current_exercise.connect("check_extra_life", _try_use_extra_life)
		exercises_control.current_exercise.connect("answer_partial_correct", _on_multiplayer_partial_correct)
	else:
		exercises_control.load_random_question()
	exercises_control.current_exercise.connect("answer_correct", _on_answer_correct)
	exercises_control.current_exercise.connect("answer_wrong", _on_answer_wrong)
	match exercises_control.current_exercise_type:
		"multiplayer_fill":
			exercises_timer.wait_time = multiplayer_fill_timer
		"fill_in_blank":
			exercises_timer.wait_time = fill_in_the_blank_timer
		"type_translation":
			exercises_timer.wait_time = type_translation_timer
		"vocabulary":
			exercises_timer.wait_time = vocabulary_timer
		_:
			exercises_timer.wait_time = 40.0
	exercises_timer.start()

func start_matchmaking() -> void:
	exercises_control.hide()
	ui_elements.show_matchmaking_screen()
	multiplayer_control.enter_matchmaking()

func _on_partner_found() -> void:
	print("[NAKAMA DEBUG] achou partner")
	# TODO mehlorar o timer, de preferência remover por completo
	# Cria um timer para que não envie o nome imediatamente, pq é possível que não tenha atualizado o server ainda e o outro player não esteja considerado "dentro da sala"
	await get_tree().create_timer(1.0).timeout
	var username = await NakamaManager.get_my_username()
	chat_control.update_player_username(username)
	multiplayer_control.send_data(multiplayer_control.DATA_TYPE.USERNAME, username)

func _on_considering_answer_multiplayer(answer: String) -> void:
	multiplayer_control.send_data(multiplayer_control.DATA_TYPE.CONSIDER_ANSWER, answer)
	chat_control.add_message("SISTEMA", await NakamaManager.get_my_username() + " está considerando " + answer, 2)
	
func _on_submit_answer_multiplayer(answer: String) -> void:
	multiplayer_control.send_data(multiplayer_control.DATA_TYPE.SUBMIT_ANSWER, answer)
	chat_control.add_message("SISTEMA", await NakamaManager.get_my_username() + " respondeu " + answer, 2)
	
func _on_send_chat_message(message: String) -> void:
	multiplayer_control.send_data(multiplayer_control.DATA_TYPE.CHAT_MESSAGE, message)

func _on_data_received(data) -> void:
	var data_type = data["type"]
	var data_value = data["value"]
	match data_type:
		multiplayer_control.DATA_TYPE.USERNAME:
			partner_username = data_value
			ui_elements.update_partner_found(partner_username)
		multiplayer_control.DATA_TYPE.CONSIDER_ANSWER:
			chat_control.add_message("SISTEMA", partner_username + " está considerando " + data_value, 2)
		multiplayer_control.DATA_TYPE.SUBMIT_ANSWER:
			partner_answer = data_value
			exercises_control.current_exercise.on_partner_answer_received(partner_answer)
			chat_control.add_message("SISTEMA", partner_username + " respondeu " + partner_answer, 2)
		multiplayer_control.DATA_TYPE.CHAT_MESSAGE:
			var partner_message = data_value
			chat_control.add_message(partner_username, partner_message, 1)
		_:
			push_error("Tipo de dado desconhecido: " + str(data["type"]))

func _on_powerup_double() -> void:
	_activate_power_up("double")

func _on_powerup_life() -> void:
	_activate_power_up("life")

func _activate_power_up(power_type: String) -> void:
	match power_type:
		"double": double_points_active = true
		"life": extra_life_active = true
	
	power_up.hide()
	ui_elements.update_powerup_icons(double_points_active, extra_life_active)
	_save_session()
	POWERUP_CHOOSED = true
	next_step_after_answer()

func _try_use_extra_life() -> bool:
	if extra_life_active:
		if exercises_control.current_exercise != null and exercises_control.current_exercise.has_method("use_extra_life"):
			exercises_control.current_exercise.use_extra_life()
		extra_life_active = false
		ui_elements.update_powerup_icons(double_points_active, extra_life_active)
		exercises_timer.start()
		return true
	if exercises_control.current_exercise != null and exercises_control.current_exercise.has_method("submit_answer"):
		exercises_control.current_exercise.submit_answer()
	return false

func finish_game() -> void:
	SaveManager.finish_session(multiplayer_control.is_multiplayer_session(), score)
	ui_elements.hide()
	exercises_control.hide()
#	TODO arrumar isso
	$GameOverScreen/FinalLabel.text += str(score)
	$GameOverScreen.show()

func _save_session() -> void:
	SaveManager.save_session(
		multiplayer_control.is_multiplayer_session(),
		score,
		question_count + 1,
		double_points_active,
		extra_life_active
	)

func _on_popup_button_pressed() -> void:
	next_step_after_answer()
	multiplayer_control.leave_match()

func _on_show_players_button_pressed() -> void:
	player_score.visible = !player_score.visible
	if player_score.visible:
		multiplayer_control.get_leaderboard_nakama()

func _on_final_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/main-menu.tscn")

func _on_tree_exited() -> void:
	if NakamaManager.socket: NakamaManager.socket.close()
