extends Control

signal answer_correct
signal answer_wrong

var questions: Array
var current_question: Dictionary
var custom_data_file: String = ""
var specific_id: String = ""

func initialize(data_file: String = "vocabulary.json", question_id: String = "") -> void:
	custom_data_file = data_file
	specific_id = question_id
	
	if not specific_id.is_empty():
		current_question = ExercisesBank.load_question_by_id(custom_data_file, specific_id)
		if current_question.is_empty():
			push_error("Question ID not found: ", specific_id)
			current_question = ExercisesBank.load_random_question(custom_data_file)
	else:
		current_question = ExercisesBank.load_random_question(custom_data_file)
	
	setup_question_display()

func load_new_question() -> void:
	current_question = questions.pick_random()
	setup_question_display()

func setup_question_display() -> void:
	var img_path = "res://src/assets/images/%s" % current_question.image
	var tex = load(img_path)
	if tex:
		$QuestionImage.texture = tex
	else:
		push_error("Falha ao carregar imagem: %s" % img_path)
	setup_buttons()

func setup_buttons() -> void:
	var options = current_question.options.duplicate()
	options.shuffle()
	
	for i in 4:
		var button = $VBoxContainer.get_child(floor(i / 2.0)).get_child(i % 2)
		button.text = options[i]

func _on_button_pressed(button: Button) -> void:
	if button.text == current_question.correct_answer:
		emit_signal("answer_correct")
	else:
		emit_signal("answer_wrong")

func _on_button_1_pressed() -> void:
	_on_button_pressed($VBoxContainer/HBoxContainer/Button1)

func _on_button_2_pressed() -> void:
	_on_button_pressed($VBoxContainer/HBoxContainer/Button2)

func _on_button_3_pressed() -> void:
	_on_button_pressed($VBoxContainer/HBoxContainer2/Button3)

func _on_button_4_pressed() -> void:
	_on_button_pressed($VBoxContainer/HBoxContainer2/Button4)
