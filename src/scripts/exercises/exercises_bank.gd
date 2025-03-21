extends Node

const QUESTION_PATH = "res://src/assets/exercises/"

func load_questions(file_name: String) -> Array:
	var full_path = QUESTION_PATH + file_name
	var questions = []
	
	if FileAccess.file_exists(full_path):
		var file = FileAccess.open(full_path, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		if json is Array:
			questions = json
		else:
			push_error("Invalid format in " + file_name)
	else:
		push_error("Question file not found: " + full_path)
	
	return questions
