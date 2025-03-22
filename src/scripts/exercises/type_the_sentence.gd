extends Control

signal answer_correct
signal answer_wrong

var questions: Array 
var current_question: Dictionary

func initialize(data_file: String) -> void:
	questions = ExercisesBank.load_questions(data_file)
	if questions.is_empty():
		push_error("Nenhuma pergunta carregada para: " + data_file)
		return
	
	load_new_question()

func load_new_question() -> void:
	current_question = questions.pick_random()
	setup_question_display()

func setup_question_display() -> void:
	$OriginalTextLabel.text = current_question.original 
	$LineEdit.text = ""

func validate_answer(answer: String) -> bool:
	var normalized_answer = answer.to_lower().strip_edges()
	
	for correct in current_question.correct_answers:
		if normalized_answer == correct.to_lower().strip_edges():
			return true
	
	return false

func _on_submit_button_pressed() -> void:
	var user_answer = $LineEdit.text
	
	if validate_answer(user_answer):
		emit_signal("answer_correct")
	else:
		emit_signal("answer_wrong")
