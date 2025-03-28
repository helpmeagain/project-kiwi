extends Control

signal answer_correct
signal answer_wrong

var questions: Array
var current_question: Dictionary

func initialize(data_file: String) -> void:
	questions = ExercisesBank.load_questions(data_file)
	if questions.is_empty():
		push_error("No questions for: " + data_file)
		return
	load_new_question()

func load_new_question() -> void:
	current_question = questions.pick_random()
	setup_question_display()

func setup_question_display() -> void:
	$QuestionLabel.text = current_question.sentence
	setup_buttons()

func setup_buttons() -> void:
	var options = current_question.options.duplicate()
	options.shuffle()
	
	for i in 4:
		var button = get_node("Button" + str(i + 1))
		button.text = options[i]

func _on_button_pressed(button: Button) -> void:
	if button.text == current_question.correct_answer:
		emit_signal("answer_correct")
	else:
		emit_signal("answer_wrong")

func _on_button_1_pressed() -> void:
	_on_button_pressed($Button1)

func _on_button_2_pressed() -> void:
	_on_button_pressed($Button2)

func _on_button_3_pressed() -> void:
	_on_button_pressed($Button3)

func _on_button_4_pressed() -> void:
	_on_button_pressed($Button4)
