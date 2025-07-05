class_name ExerciseManager
extends Node

# Configurações
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

const MAX_QUESTIONS = 30
const POWERUP_INTERVAL := 3

# Referências
var parent: Control
var current_question: Node
var current_exercise_type: String

# Rastreamento de questões usadas
var used_question_ids: Dictionary = {}

func _init(parent_node: Control) -> void:
	parent = parent_node
	for exercise_type in EXERCISE_DATA_FILES:
		used_question_ids[exercise_type] = []

func load_random_question() -> void:
	if parent.question_count >= MAX_QUESTIONS:
		return
	
	cleanup_current_question()
	if parent.question_count % 2 == 1 && parent.multiplayer_manager.is_multiplayer():
		print("[DEBUG] Entrando no matchmaking para exercício multiplayer")
		parent.multiplayer_manager.enter_matchmaking()
		parent.ui_manager.set_random_background("fade")
		return
		
	var exercise_weights = {
		"fill_in_blank": 1.5,
		"type_translation": 1.0,
		"vocabulary": 1.5
	}
	
	#print("\n[DEBUG] IDs já usados:")
	#for exercise_type in used_question_ids:
		#var ids = used_question_ids[exercise_type]
		#if ids.size() > 0:
			#print("  ", exercise_type, ": ", ", ".join(ids))
		#else:
			#print("  ", exercise_type, ": Nenhum")
			
	var candidates = []
	var total_weight = 0.0
	
	for key in EXERCISE_CONFIG:
		if key == "multiplayer_fill": 
			continue
		
		var weight = exercise_weights.get(key, 1.0)
		total_weight += weight
		candidates.append({"key": key, "weight": weight, "cumulative": total_weight})
	
	var random_value = randf() * total_weight
	var selected_exercise = "fill_in_blank"
	
	for candidate in candidates:
		if random_value <= candidate["cumulative"]:
			selected_exercise = candidate["key"]
			break
	
	current_exercise_type = selected_exercise
	var config = EXERCISE_CONFIG[selected_exercise]
	var data_file = EXERCISE_DATA_FILES[selected_exercise]

	var scene = load(config).instantiate()
	parent.get_node("QuestionsContainer").add_child(scene)
	var question_data = get_unused_question(selected_exercise, data_file)
	
	if question_data.is_empty():
		push_error("Não foi possível carregar questão para " + selected_exercise)
		scene.queue_free()
		load_random_question()
		return
	
	if scene.has_method("initialize"):
		scene.initialize(data_file, question_data.id)
	else:
		push_error("Exercise scene missing initialize() method")
	
	current_question = scene
	parent.question_count += 1
	parent.timeout_occurred = false
	
	if question_data.has("id"):
		used_question_ids[selected_exercise].append(question_data.id)
		# print("Questão usada: ", selected_exercise, " - ID: ", question_data.id)

	setup_exercise_signals()
	parent.ui_manager.update_question_count(parent.question_count)
	parent.timer_manager.start_timer_for_exercise(current_exercise_type)
	parent.ui_manager.set_random_background("fade")

func get_unused_question(exercise_type: String, data_file: String) -> Dictionary:
	var all_questions = ExercisesBank.load_questions(data_file).all
	var used_ids = used_question_ids[exercise_type]
	
	if all_questions.size() == 0:
		push_error("Nenhuma questão encontrada para " + data_file)
		return {}
	
	var unused_questions = []
	for q in all_questions:
		if q.has("id") and not used_ids.has(q.id):
			unused_questions.append(q)
	
	if unused_questions.size() == 0:
		print("Reciclando histórico de questões para: ", exercise_type)
		used_question_ids[exercise_type] = []
		return all_questions.pick_random()
	
	return unused_questions.pick_random()
	
func load_multiplayer_exercise(partner_id: int, question_data: Dictionary) -> void:
	cleanup_current_question()
	
	var config = EXERCISE_CONFIG["multiplayer_fill"]
	var scene = load(config).instantiate()
	parent.get_node("QuestionsContainer").add_child(scene)
	
	current_question = scene
	parent.question_count += 1
	parent.timeout_occurred = false
	parent.ui_manager.update_question_count(parent.question_count)
	
	if scene.has_method("initialize"):
		scene.initialize(
			parent,
			question_data, 
			multiplayer.get_unique_id(), 
			partner_id 
		)
	else:
		push_error("Multiplayer exercise scene missing initialize() method")
		return
	
	if current_question.has_signal("answer_correct"):
		current_question.connect("answer_correct", parent._on_answer_correct)
	if current_question.has_signal("answer_wrong"):
		current_question.connect("answer_wrong", parent._on_answer_wrong)

func determine_player_index(partner_id: int) -> int:
	var ids = [multiplayer.get_unique_id(), partner_id]
	ids.sort()
	return ids.find(multiplayer.get_unique_id())

func cleanup_current_question() -> void:
	if current_question:
		current_question.queue_free()

func setup_exercise_signals() -> void:
	if current_question.has_signal("answer_correct"):
		current_question.connect("answer_correct", parent._on_answer_correct)
	if current_question.has_signal("answer_wrong"):
		current_question.connect("answer_wrong", parent._on_answer_wrong)

func get_correct_answer() -> String:
	var qd = current_question.current_question
	if qd.has("correct_answers"):
		return qd.correct_answers[0] if qd.correct_answers.size() > 0 else "—"
	elif qd.has("correct_answer"):
		return qd.correct_answer
	return "—"

func has_current_question() -> bool:
	return current_question != null
