extends Control

signal answer_correct
signal answer_wrong
signal send_considering_answer(answer)
signal send_submit_answer(answer)
signal check_extra_life

var current_question: Dictionary
var player_answer: String = ""
var partner_answer: String = ""
var answered: bool = false
var partner_answered: bool = false
var selected_button: Button = null

@onready var buttons_container = $VBoxContainer
@onready var buttons = [
	$VBoxContainer/HBoxContainer1/Button1,
	$VBoxContainer/HBoxContainer1/Button2,
	$VBoxContainer/HBoxContainer2/Button3,
	$VBoxContainer/HBoxContainer2/Button4
]

func initialize(question_id: String = "", data_file: String = "multiplayer_fill_in_the_blank.json") -> void:	
	if question_id == "":
		current_question = ExercisesBank.load_random_question(data_file)
	else:
		current_question = ExercisesBank.load_question_by_id(data_file, question_id)
		if current_question.is_empty():
			push_error("Question ID not found: ", question_id)
			current_question = ExercisesBank.load_random_question(data_file)
	
	setup_label_and_buttons()

func setup_label_and_buttons() -> void:
	$QuestionLabel.text = current_question.sentence
	var options = current_question.options[0].duplicate()
	options.shuffle()
	
	for i in 4:
		var button = buttons_container.get_child(floor(i / 2.0)).get_child(i % 2)
		button.text = options[i]
	
	$SubmitButton.disabled = true

func _on_button_pressed(button: Button) -> void:
	if answered:
		return
	
	selected_button = button
	player_answer = button.text
	$SubmitButton.disabled = false
	emit_signal("send_considering_answer", player_answer)

func _on_submit_button_pressed() -> void:
	if !selected_button or answered:
		return
	
	$SubmitButton.disabled = true
	var correct_answer = current_question.correct_answers[0]
	var is_correct = (player_answer == correct_answer)
	if !is_correct:
		emit_signal("check_extra_life")
		return
#	TODO CORRIGIR SE TIVER UMA SEGUNDA VIDA
	#if !is_correct && parent.power_up_manager.use_extra_life():
		#parent.ui_manager.update_powerup_icons()
		#answered = false
		#player_answer = ""
		#$SubmitButton.disabled = true
		#selected_button.disabled = true
		#selected_button.mouse_filter = Control.MOUSE_FILTER_STOP
		#selected_button.set_default_cursor_shape(Control.CURSOR_ARROW)
		#selected_button.set_focus_mode(Control.FOCUS_NONE)
		#selected_button.add_theme_color_override("font_disabled_color", Color.DARK_RED)
		#return
	submit_answer()

func use_extra_life() -> void:
	if answered:
		return
	answered = false
	player_answer = ""
	$SubmitButton.disabled = true
	print(selected_button)
	selected_button.disabled = true
	selected_button.mouse_filter = Control.MOUSE_FILTER_STOP
	selected_button.set_default_cursor_shape(Control.CURSOR_ARROW)
	selected_button.set_focus_mode(Control.FOCUS_NONE)
	selected_button.add_theme_color_override("font_disabled_color", Color.DARK_RED)
	return

func submit_answer() -> void:
	answered = true
	for btn in buttons:
		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE
	
	emit_signal("send_submit_answer", player_answer)
	#$PartnerAnswerLabel.text = "Waiting for partner's answer..."
	#$PartnerAnswerLabel.show()
	check_answers()

func on_partner_answer_received(answer: String) -> void:
	partner_answer = answer
	partner_answered = true
	check_answers()

func check_answers() -> void:
	if not (answered and partner_answered):
		return
	
	var correct_answer = current_question.correct_answers[0]
	var player_correct = player_answer == correct_answer
	var partner_correct = partner_answer == correct_answer
	var consensus = player_answer == partner_answer
	
	$ResultLabel.text = "Your answer: " + player_answer + (" ✓" if player_correct else " ✗")
	$ResultLabel.text += "\nPartner's answer: " + partner_answer + (" ✓" if partner_correct else " ✗")
	$ResultLabel.text += "\n\n"
	
	if player_correct && partner_correct && consensus:
		$ResultLabel.text += "Perfect consensus! +2 points"
		emit_signal("answer_correct", 2)
	elif consensus && player_correct:
		$ResultLabel.text += "Agreed on correct answer! +1 point"
		emit_signal("answer_correct", 1)
	elif consensus:
		$ResultLabel.text += "Agreed but wrong answer!"
		emit_signal("answer_wrong")
	else:
		$ResultLabel.text += "Disagreement! No points"
		emit_signal("answer_wrong")
	
	$ResultLabel.show()

func _on_button_1_pressed() -> void: _on_button_pressed(buttons[0])
func _on_button_2_pressed() -> void: _on_button_pressed(buttons[1])
func _on_button_3_pressed() -> void: _on_button_pressed(buttons[2])
func _on_button_4_pressed() -> void: _on_button_pressed(buttons[3])
