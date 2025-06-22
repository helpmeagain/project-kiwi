extends Control

signal answer_correct
signal answer_wrong

var current_question: Dictionary
var player_id: int
var partner_id: int = -1
var player_index: int 
var player_answer: String = ""
var partner_answer: String = ""
var answered: bool = false
var partner_answered: bool = false
var parent: Control

func initialize(parent_node: Control, question_data: Dictionary, p_id: int, p_index: int, p_partner_id: int) -> void:
	parent = parent_node
	current_question = question_data
	player_id = p_id
	player_index = p_index
	partner_id = p_partner_id
	
	print("[EXERCISE] Initializing for player:", player_id, " partner:", partner_id)
	
	setup_question_display()
	setup_buttons()
	
	if not multiplayer.has_signal("partner_answer_received"):
		multiplayer.add_user_signal("partner_answer_received", [
			{"name": "partner_id", "type": TYPE_INT},
			{"name": "answer", "type": TYPE_STRING}
		])
	
	# Conectar o sinal apenas uma vez
	if not multiplayer.is_connected("partner_answer_received", _on_partner_answer_received):
		multiplayer.connect("partner_answer_received", _on_partner_answer_received)

func setup_question_display() -> void:
	$QuestionLabel.text = current_question.sentence
	$PlayerLabel.text = "You are filling blank #" + str(player_index + 1)

func setup_buttons() -> void:
	var options = current_question.options[player_index].duplicate()
	options.shuffle()
	
	for i in 4:
		var button = $VBoxContainer.get_child(floor(i / 2.0)).get_child(i % 2)
		button.text = options[i]
		button.show()

func _on_button_pressed(button: Button) -> void:
	if answered:
		return
	
	player_answer = button.text
	var correct_answer = current_question.correct_answers[player_index]
	var is_correct = (player_answer == correct_answer)
	if !is_correct && parent.power_up_manager.use_extra_life():
		parent.ui_manager.update_ui_components(parent.score, parent.question_count)
		answered = false
		player_answer = ""
		return
	answered = true
	var buttons = [
		$VBoxContainer/HBoxContainer/Button1,
		$VBoxContainer/HBoxContainer/Button2,
		$VBoxContainer/HBoxContainer2/Button3,
		$VBoxContainer/HBoxContainer2/Button4
	]
	
	for btn in buttons:
		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE
	
	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if multiplayer.get_unique_id() != 1:
		parent.multiplayer_manager.submit_answer.rpc_id(1, multiplayer.get_unique_id(), player_answer)
	else:
		parent.multiplayer_manager._receive_answer_locally(multiplayer.get_unique_id(), player_answer)
	
	check_answers()

func _on_partner_answer_received(received_partner_id: int, answer: String) -> void:
	print("[NETWORK] Received answer from:", received_partner_id)
	
	if partner_id != received_partner_id:
		print("[NETWORK] Ignoring answer - not from my partner")
		return
	
	partner_answer = answer
	partner_answered = true
	$PartnerAnswerLabel.text = "Partner answered: " + answer
	$PartnerAnswerLabel.show()
	
	print("[NETWORK] Partner answer processed:", answer)
	check_answers()

func check_answers() -> void:
	if not (answered and partner_answered):
		return
	
	var player_correct = player_answer == current_question.correct_answers[player_index]
	var partner_correct = partner_answer == current_question.correct_answers[1 - player_index]
	
	$ResultLabel.text = "Your answer: " + player_answer + (" ✓" if player_correct else " ✗")
	$ResultLabel.text += "\nPartner's answer: " + partner_answer + (" ✓" if partner_correct else " ✗")
	$ResultLabel.show()
	
	var base_points = 0
	if player_correct && partner_correct:
		base_points = 2
	elif player_correct:
		base_points = 1
	
	if base_points > 0:
		emit_signal("answer_correct", base_points)
	else:
		emit_signal("answer_wrong")
	
	$Timer.start(2.0)

func _on_timer_timeout() -> void:
	queue_free()

func _on_button_1_pressed() -> void:
	_on_button_pressed($VBoxContainer/HBoxContainer/Button1)

func _on_button_2_pressed() -> void:
	_on_button_pressed($VBoxContainer/HBoxContainer/Button2)

func _on_button_3_pressed() -> void:
	_on_button_pressed($VBoxContainer/HBoxContainer2/Button3)

func _on_button_4_pressed() -> void:
	_on_button_pressed($VBoxContainer/HBoxContainer2/Button4)
