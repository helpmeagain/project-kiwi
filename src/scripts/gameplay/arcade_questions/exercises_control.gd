class_name ExercisesControl
extends Control

var current_exercise: Node
var current_exercise_type: String
var used_exercises_ids: Dictionary = {}

const EXERCISE_CONFIG = {
	"fill_in_blank": "res://src/scenes/exercises/fill-in-the-blank.tscn",
	#"listen_then_type": "res://src/scenes/exercises/listen-then-type.tscn",
	"type_translation": "res://src/scenes/exercises/type-the-sentence.tscn",
	"multiplayer_fill": "res://src/scenes/exercises/multiplayer-fill-in-the-blank.tscn",
	"vocabulary" : "res://src/scenes/exercises/vocabulary.tscn"
}

const EXERCISE_DATA_FILES = {
	"fill_in_blank": "fill_in_the_blank.json",
	"type_translation": "type-the-sentence.json",
	"vocabulary": "vocabulary.json"
}

# TODO evitar recursão infinita
func load_random_question() -> void:
	if current_exercise: current_exercise.queue_free()
	current_exercise_type = select_random_exercise_type()
	
	var config = EXERCISE_CONFIG[current_exercise_type]
	var data_file = EXERCISE_DATA_FILES[current_exercise_type]
	var scene = load(config).instantiate()
	self.add_child(scene)
	
	var question_data = get_unused_question(current_exercise_type, data_file)
	if question_data.is_empty():
		push_error("Não foi possível carregar questão para " + current_exercise_type)
		scene.queue_free()
		load_random_question()
		return
	
	initialize_question(scene, data_file, question_data)
	
func load_multiplayer_question(match_id: String) -> void:
	if current_exercise: current_exercise.queue_free()
	
	var config = EXERCISE_CONFIG["multiplayer_fill"]
	var scene = load(config).instantiate()
	self.add_child(scene)
	
	var exercise_id = _get_deterministic_exercise_id(match_id)
	scene.initialize(exercise_id)
	current_exercise = scene

func _get_deterministic_exercise_id(match_id: String) -> String:
	var rng = RandomNumberGenerator.new()
	rng.seed = match_id.hash()
	
	var all_exercises = ExercisesBank.load_questions("multiplayer_fill_in_the_blank.json").all
	
	var index = rng.randi_range(0, all_exercises.size() - 1)
	return all_exercises[index].id

func select_random_exercise_type() -> String:
	const EXERCISE_WEIGHTS := {
		"fill_in_blank": 1.5,
		"type_translation": 1.0,
		"vocabulary": 1.5
	}
	
	var eligible_exercises := EXERCISE_CONFIG.keys().filter(
		func(key): return key != "multiplayer_fill" and EXERCISE_WEIGHTS.has(key)
	)
	
	var cumulative_weights := []
	var total_weight := 0.0
	
	for exercise in eligible_exercises:
		total_weight += EXERCISE_WEIGHTS[exercise]
		cumulative_weights.append(total_weight)
	
	var random_value := randf() * total_weight
	
	for i in eligible_exercises.size():
		if random_value <= cumulative_weights[i]:
			return eligible_exercises[i]
	
	return eligible_exercises.back()

func get_unused_question(exercise_type: String, data_file: String) -> Dictionary:
	if not used_exercises_ids.has(exercise_type):
		used_exercises_ids[exercise_type] = []
	
	var all_questions = ExercisesBank.load_questions(data_file).all
	var unused_questions = all_questions.filter(
		func(q): return not used_exercises_ids[exercise_type].has(q.id)
	)
	
	if unused_questions.is_empty():
		used_exercises_ids[exercise_type] = []
		return all_questions.pick_random() if not all_questions.is_empty() else {}
	
	return unused_questions.pick_random()
	
func initialize_question(scene: Node, data_file: String, question_data: Dictionary) -> void:
	scene.initialize(data_file, question_data.id)
	current_exercise = scene
	used_exercises_ids[current_exercise_type].append(question_data.id)

func get_correct_answer() -> String:
	var qd = current_exercise.current_question
	
	if qd.has("correct_answers") and qd.correct_answers.size() > 0:
		return ", \n".join(qd.correct_answers)
	elif qd.has("correct_answer"):
		return qd.correct_answer
	return "—"

#func DEBUG_get_used_questions() -> void:
	#print("\n[DEBUG] IDs used:")
	#for exercise_type in used_exercises_ids:
		#var ids = used_exercises_ids[exercise_type]
		#if ids.size() > 0:
			#print("  ", exercise_type, ": ", ", ".join(ids))
		#else:
			#print("  ", exercise_type, ": Nothing")
