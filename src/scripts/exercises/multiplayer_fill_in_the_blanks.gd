extends Control

signal answer_correct
signal answer_wrong

var current_question: Dictionary
var player_id: int
var partner_id: int = -1
var player_answer: String = ""
var partner_answer: String = ""
var answered: bool = false
var partner_answered: bool = false
var parent: Control
var selected_button: Button = null

@onready var buttons_container = $VBoxContainer
@onready var buttons = [
	$VBoxContainer/HBoxContainer1/Button1,
	$VBoxContainer/HBoxContainer1/Button2,
	$VBoxContainer/HBoxContainer2/Button3,
	$VBoxContainer/HBoxContainer2/Button4
]

func initialize(parent_node: Control, question_data: Dictionary, p_id: int, p_partner_id: int) -> void:
	print("[EXERCISE - MULTIPLAYER FILL IN THE BLANKS] Initializing for player: ", player_id, " | partner: ", partner_id)
	parent = parent_node
	current_question = question_data
	player_id = p_id
	partner_id = p_partner_id
	setup_question_display()
	setup_buttons()
	
	if not multiplayer.has_signal("partner_selection_received"):
		multiplayer.add_user_signal("partner_selection_received", [
			{"name": "partner_id", "type": TYPE_INT},
			{"name": "selection", "type": TYPE_STRING}
		])
	
	if not multiplayer.has_signal("partner_answer_received"):
		multiplayer.add_user_signal("partner_answer_received", [
			{"name": "partner_id", "type": TYPE_INT},
			{"name": "answer", "type": TYPE_STRING}
		])
	
	if not multiplayer.is_connected("partner_selection_received", _on_partner_selection_received):
		multiplayer.connect("partner_selection_received", _on_partner_selection_received)
	
	if not multiplayer.is_connected("partner_answer_received", _on_partner_answer_received):
		multiplayer.connect("partner_answer_received", _on_partner_answer_received)

func setup_question_display() -> void:
	$QuestionLabel.text = current_question.sentence
	$PartnerAnswerLabel.hide()

func setup_buttons() -> void:
	var options = current_question.options[0].duplicate()
	options.shuffle()
	
	for i in 4:
		var button = buttons_container.get_child(floor(i / 2.0)).get_child(i % 2)
		button.text = options[i]
		button.show()
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	$SubmitButton.disabled = true

func _on_button_pressed(button: Button) -> void:
	if answered:
		return
	
	selected_button = button
	player_answer = button.text
	$SubmitButton.disabled = false
	
	if multiplayer.get_unique_id() != 1:
		parent.multiplayer_manager.submit_selection.rpc_id(1, multiplayer.get_unique_id(), player_answer)
	else:
		parent.multiplayer_manager._receive_selection_locally(multiplayer.get_unique_id(), player_answer)

func _on_submit_button_pressed() -> void:
	if !selected_button or answered:
		return
	
	$SubmitButton.disabled = true
	
	var correct_answer = current_question.correct_answers[0]
	var is_correct = (player_answer == correct_answer)
	if !is_correct && parent.power_up_manager.use_extra_life():
		parent.ui_manager.update_powerup_icons()
		answered = false
		player_answer = ""
		$SubmitButton.disabled = true
		selected_button.disabled = true
		selected_button.mouse_filter = Control.MOUSE_FILTER_STOP
		selected_button.set_default_cursor_shape(Control.CURSOR_ARROW)
		selected_button.set_focus_mode(Control.FOCUS_NONE)
		selected_button.add_theme_color_override("font_disabled_color", Color.DARK_RED)
		return
	
	answered = true
	
	for btn in buttons:
		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE
	
	if multiplayer.get_unique_id() != 1:
		parent.multiplayer_manager.submit_answer.rpc_id(1, multiplayer.get_unique_id(), player_answer)  # Alterado para submit_answer
	else:
		parent.multiplayer_manager._receive_answer_locally(multiplayer.get_unique_id(), player_answer) 
	
	$PartnerAnswerLabel.text = "Waiting for partner's answer..."
	$PartnerAnswerLabel.show()
	
	check_answers()

func _on_partner_selection_received(received_partner_id: int, selection: String) -> void:
	if partner_id != received_partner_id:
		return
	
	$PartnerAnswerLabel.text = "Partner is considering: " + selection
	$PartnerAnswerLabel.show()

func _on_partner_answer_received(received_partner_id: int, answer: String) -> void:
	if partner_id != received_partner_id:
		return
	
	partner_answer = answer
	partner_answered = true
	$PartnerAnswerLabel.text = "Partner answered: " + answer
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
	queue_free()

func _on_button_1_pressed() -> void: _on_button_pressed(buttons[0])
func _on_button_2_pressed() -> void: _on_button_pressed(buttons[1])
func _on_button_3_pressed() -> void: _on_button_pressed(buttons[2])
func _on_button_4_pressed() -> void: _on_button_pressed(buttons[3])
