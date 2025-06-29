extends Node

const QUESTION_PATH = "res://src/assets/exercises/"

func load_questions(file_name: String) -> Dictionary:
	var full_path = QUESTION_PATH + file_name
	var questions = {
		"all": [],
		"by_id": {}
	}
	
	if FileAccess.file_exists(full_path):
		var file = FileAccess.open(full_path, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		if json is Array:
			for question in json:
				if "id" in question:
					questions.by_id[question.id] = question
					questions.all.append(question)
				else:
					push_error("Question without ID in " + file_name)
		else:
			push_error("Invalid format in " + file_name)
	else:
		push_error("Question file not found: " + full_path)
	
	return questions

func load_random_question(file_name: String) -> Dictionary:
	var questions = load_questions(file_name)
	if not questions.all.is_empty():
		return questions.all.pick_random()
	else:
		push_error("No questions found in " + file_name)
		return {}
		
func load_question_by_id(file_name: String, question_id: String) -> Dictionary:
	var questions = load_questions(file_name)
	return questions.by_id.get(question_id, {})
