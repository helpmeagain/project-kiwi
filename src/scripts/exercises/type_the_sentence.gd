extends Control

signal answer_correct
signal answer_wrong

var current_question: Dictionary
var custom_data_file: String = ""
var specific_id: String = ""
var _regex: RegEx
var _space_regex: RegEx

@onready var original_text_label = $OriginalTextLabel
@onready var text_input = $TextEdit

func initialize(data_file: String = "type-the-sentence.json", question_id: String = "") -> void:
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

func setup_question_display() -> void:
	original_text_label.text = current_question.original 
	text_input.text = ""

func _on_submit_button_pressed() -> void:
	var user_answer = text_input.text
	
	if validate_answer(user_answer):
		emit_signal("answer_correct")
	else:
		emit_signal("answer_wrong")
	#queue_free()

func validate_answer(answer: String) -> bool:
	var normalized_answer = normalize_answer(answer)
	
	for correct in current_question.correct_answers:
		if normalized_answer == normalize_answer(correct):
			return true
	
	return false

func normalize_answer(text: String) -> String:
	_regex = RegEx.new()
	_regex.compile("[^a-z0-9 ']")
	_space_regex = RegEx.new()
	_space_regex.compile("\\s+")
	var normalized = text.to_lower() 
	normalized = normalized.replace("’", "'")
	normalized = _regex.sub(normalized, "")
	normalized = _space_regex.sub(normalized, " ")
	return normalized.strip_edges()
