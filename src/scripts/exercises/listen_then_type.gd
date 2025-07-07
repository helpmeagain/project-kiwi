# WILL NOT BE USED

extends Control

signal answer_correct
signal answer_wrong

var questions: Array 
var current_question: Dictionary
var text_to_speech: String
var voices = DisplayServer.tts_get_voices_for_language("en")
var voice_id = voices[0]
var custom_data_file: String = ""
var specific_id: String = ""

func initialize(data_file: String = "listen-then-type.json", question_id: String = "") -> void:
	custom_data_file = data_file
	specific_id = question_id
	
	if specific_id.is_empty():
		var all_questions = ExercisesBank.load_questions(custom_data_file).all
		if not all_questions.is_empty():
			current_question = all_questions.pick_random()
			text_to_speech = current_question.text_to_speech
	else:
		current_question = ExercisesBank.load_question_by_id(custom_data_file, specific_id)
		if current_question.is_empty():
			push_error("Question ID not found: ", specific_id)
			return
		text_to_speech = current_question.text_to_speech

func load_new_question() -> void:
	current_question = questions.pick_random()
	text_to_speech = current_question.text_to_speech

func validate_answer(answer: String) -> bool:
	var normalized_answer = normalize_answer(answer)
	for correct in current_question.correct_answers:
		if normalized_answer == normalize_answer(correct):
			return true
	
	return false

func normalize_answer(text: String) -> String:
	return text.to_lower().strip_edges().replace("’", "'")

func _on_listen_button_pressed() -> void:
	DisplayServer.tts_speak(text_to_speech, voice_id)

func _on_submit_button_pressed() -> void:
	var user_answer = $TextEdit.text
	
	if validate_answer(user_answer):
		emit_signal("answer_correct")
	else:
		emit_signal("answer_wrong")
	queue_free()
