extends Control

# Referências
var exercise_manager: Node
var power_up_manager: Node
var timer_manager: Node
var ui_manager: Node
var multiplayer_manager: Node

# Estado do jogo
var score: int = 0
var question_count: int = 0
var timeout_occurred: bool = false

func _ready() -> void:
	initialize_managers()
	initialize_game()

func initialize_managers() -> void:
	exercise_manager = preload("res://src/scripts/multiplayer/managers/exercise_manager.gd").new(self)
	power_up_manager = preload("res://src/scripts/multiplayer/managers/power_up_manager.gd").new(self)
	timer_manager = preload("res://src/scripts/multiplayer/managers/timer_manager.gd").new(self)
	ui_manager = preload("res://src/scripts/multiplayer/managers/ui_manager.gd").new(self)
	multiplayer_manager = preload("res://src/scripts/multiplayer/managers/multiplayer_manager.gd").new(self)  # Novo
	
	add_child(exercise_manager)
	add_child(power_up_manager)
	add_child(timer_manager)
	add_child(ui_manager)
	add_child(multiplayer_manager)

func initialize_game() -> void:
	score = 0
	question_count = 0
	timeout_occurred = false
	power_up_manager.reset()
	ui_manager.initialize_ui()
	if multiplayer_manager.is_multiplayer():
		multiplayer.add_user_signal("partner_answer_received", [
			{"name": "partner_id", "type": TYPE_INT},
			{"name": "answer", "type": TYPE_STRING}
		])
	exercise_manager.load_random_question()

func _process(_delta) -> void:
	ui_manager.update_timer_display(timer_manager.get_time_left())

# --- Funções de resposta ---
func _on_answer_correct(points: int = 1) -> void:
	if timeout_occurred: return
	
	timer_manager.stop_timer()
	points *= power_up_manager.get_score_multiplier()
	score += points
	power_up_manager.deactivate_double_points()
	ui_manager.update_ui_components(score, question_count)
	multiplayer_manager.update_score(score)
	next_step_after_answer()

func _on_answer_wrong() -> void:
	if timeout_occurred: return
	if power_up_manager.use_extra_life():
		ui_manager.update_ui_components(score, question_count)
		timer_manager.start_timer_for_exercise(exercise_manager.current_exercise_type)
		return
	
	timer_manager.stop_timer()
	ui_manager.show_wrong_answer(exercise_manager.get_correct_answer())
	ui_manager.update_score_display(score)

# --- Fluxo do jogo ---
func next_step_after_answer() -> void:
	if question_count >= exercise_manager.MAX_QUESTIONS:
		ui_manager.show_final_screen(score)
	elif question_count % exercise_manager.POWERUP_INTERVAL == 0:
		ui_manager.show_powerup_screen()
	else:
		exercise_manager.load_random_question()

# --- Eventos do timer ---
func _on_timer_timeout() -> void:
	timer_manager.stop_timer()
	if power_up_manager.use_extra_life():
		timeout_occurred = false
		ui_manager.update_ui_components(score, question_count)
		timer_manager.start_timer_for_exercise(exercise_manager.current_exercise_type)
		return
	
	timeout_occurred = true
	if exercise_manager.has_current_question():
		ui_manager.show_timeout_message(exercise_manager.get_correct_answer())
	else:
		next_step_after_answer()

# --- Power-up handlers ---
func _on_powerup_double() -> void:
	power_up_manager.activate_double_points()
	ui_manager.hide_powerup_screen()
	ui_manager.update_powerup_icons()
	exercise_manager.load_random_question()

func _on_powerup_life() -> void:
	power_up_manager.activate_extra_life()
	ui_manager.hide_powerup_screen()
	ui_manager.update_powerup_icons()
	exercise_manager.load_random_question()

# --- UI handlers ---
func _on_wrong_panel_button_pressed() -> void:
	ui_manager.hide_wrong_answer()
	next_step_after_answer()

func _on_show_players_button_pressed() -> void:
	ui_manager.toggle_player_score_display()
