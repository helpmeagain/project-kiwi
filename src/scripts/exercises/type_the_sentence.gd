extends Control

signal answer_correct
signal answer_wrong

var questions: Array 
var current_question: Dictionary
var custom_data_file: String = ""
var specific_id: String = ""

func initialize(data_file: String = "type-the-sentence.json", question_id: String = "") -> void:
	custom_data_file = data_file
	specific_id = question_id
	
	if specific_id.is_empty():
		var all_questions = ExercisesBank.load_questions(custom_data_file).all
		if not all_questions.is_empty():
			current_question = all_questions.pick_random()
			setup_question_display()
	else:
		current_question = ExercisesBank.load_question_by_id(custom_data_file, specific_id)
		if current_question.is_empty():
			push_error("Question ID not found: ", specific_id)
			return
		setup_question_display()

func load_new_question() -> void:
	current_question = questions.pick_random()
	setup_question_display()

func setup_question_display() -> void:
	$OriginalTextLabel.text = current_question.original 
	$TextEdit.text = ""

func validate_answer(answer: String) -> bool:
	var normalized_answer = answer.to_lower().strip_edges()
	
	for correct in current_question.correct_answers:
		if normalized_answer == correct.to_lower().strip_edges():
			return true
	
	return false

func _on_submit_button_pressed() -> void:
	var user_answer = $TextEdit.text
	
	if validate_answer(user_answer):
		emit_signal("answer_correct")
	else:
		emit_signal("answer_wrong")
