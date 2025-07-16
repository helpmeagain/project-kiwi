extends Control

# TODO deletar manager e funções depois
var multiplayer_manager: Node

@onready var ui_elements: UIControl = $UIElements
@onready var power_up: Control = $PowerUpSelection
@onready var background: BackgroundImage = $BackgroundImage
@onready var game_over: Control = $GameOverScreen
@onready var exercises_control: ExercisesControl = $ExercisesControl
@onready var exercises_timer: Timer = $ExerciseTimer

@export var score: int = 0
@export var question_count: int = 0
@export var max_questions = 5
@export var power_up_interval = 3
var timeout_occurred: bool = false
var double_points_active: bool = false
var extra_life_active: bool = false

func _ready() -> void:
	initialize_managers()
	if multiplayer_manager.is_multiplayer():
		multiplayer.add_user_signal("partner_answer_received", [
			{"name": "partner_id", "type": TYPE_INT},
			{"name": "answer", "type": TYPE_STRING}
		])
	load_next_exercise()
	try_restore_active_session()
	ui_elements.max_questions = max_questions
	ui_elements.update_all_ui_components(score, question_count, double_points_active, extra_life_active)

func _process(_delta) -> void:
	ui_elements.update_timer_label(exercises_timer.time_left)

func initialize_managers() -> void:
	multiplayer_manager = preload("res://src/scripts/multiplayer/managers/multiplayer_manager.gd").new(self)
	add_child(multiplayer_manager)

func try_restore_active_session() -> bool:
	var is_multi = multiplayer_manager.is_multiplayer()
	var saved_data = SaveManager.load_session(is_multi)
	
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
	if double_points_active:
		score += points * 2
		double_points_active = false
	else:
		score += points
	PopupManager.instance().ok_pressed.connect(_on_popup_button_pressed)
	PopupManager.show_congratulations_answer(exercises_control.get_correct_answer())
	ui_elements.update_all_ui_components(score, question_count, double_points_active, extra_life_active)
	multiplayer_manager.update_score(score)

func _on_answer_wrong() -> void:
	if timeout_occurred: return
	if _try_use_extra_life():
		return
	
	exercises_timer.stop()
	PopupManager.instance().ok_pressed.connect(_on_popup_button_pressed)
	PopupManager.show_wrong_answer(exercises_control.get_correct_answer())
	ui_elements.update_all_ui_components(score, question_count, double_points_active, extra_life_active)

func _on_timer_timeout() -> void:
	exercises_timer.stop()
	if _try_use_extra_life():
		return
	
	timeout_occurred = true
	if exercises_control.current_exercise != null:
		PopupManager.instance().ok_pressed.connect(_on_popup_button_pressed)
		PopupManager.show_timeout_message(exercises_control.get_correct_answer())
	else:
		next_step_after_answer()

func next_step_after_answer() -> void:
	if question_count >= max_questions:
		finish_game()
	elif question_count % power_up_interval == 0:
		power_up.show()
	else:
		_save_session()
		load_next_exercise()

func load_next_exercise() -> void:
	question_count += 1
	timeout_occurred = false
	ui_elements.update_question_count(question_count)
	exercises_timer.start()
	background.set_random_background()
	exercises_control.load_random_question()
	exercises_control.current_exercise.connect("answer_correct", _on_answer_correct)
	exercises_control.current_exercise.connect("answer_wrong", _on_answer_wrong)

func _on_powerup_double() -> void:
	_activate_power_up("double")

func _on_powerup_life() -> void:
	_activate_power_up("life")

func _activate_power_up(power_type: String) -> void:
	match power_type:
		"double":
			double_points_active = true
		"life":
			extra_life_active = true
	
	power_up.hide()
	ui_elements.update_powerup_icons(double_points_active, extra_life_active)
	_save_session()
	load_next_exercise()

func _try_use_extra_life() -> bool:
	if extra_life_active:
		extra_life_active = false
		ui_elements.update_powerup_icons(double_points_active, extra_life_active)
		exercises_timer.start()
		return true
	return false

func finish_game() -> void:
	SaveManager.finish_session(multiplayer_manager.is_multiplayer(), score)
	ui_elements.hide()
	exercises_control.hide()
#	TODO arrumar isso
	$GameOverScreen/FinalLabel.text += str(score)
	game_over.show()

func _save_session() -> void:
	SaveManager.save_session(
		multiplayer_manager.is_multiplayer(),
		score,
		question_count + 1,
		double_points_active,
		extra_life_active
	)

func _on_popup_button_pressed() -> void:
	next_step_after_answer()

func _on_show_players_button_pressed() -> void:
#	TODO Arrumar exibição do leaderboard
	#ui_manager.toggle_player_score_display()
	pass

func _on_final_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/singleplayer-menu.tscn")
