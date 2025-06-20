class_name ExerciseManager
extends Node

# Configurações
const EXERCISE_CONFIG = {
	"fill_in_blank": "res://src/scenes/exercises/fill-in-the-blank.tscn",
	"listen_then_type": "res://src/scenes/exercises/listen-then-type.tscn",
	"type_translation": "res://src/scenes/exercises/type-the-sentence.tscn"
}
const MAX_QUESTIONS = 7
const POWERUP_INTERVAL := 3

# Referências
var parent: Control
var current_question: Node
var current_exercise_type: String

func _init(parent_node: Control) -> void:
	parent = parent_node

func load_random_question() -> void:
	if parent.question_count >= MAX_QUESTIONS:
		return
	
	cleanup_current_question()
	
	var exercise_keys = EXERCISE_CONFIG.keys()
	var random_key = exercise_keys[randi() % exercise_keys.size()]
	current_exercise_type = random_key
	var config = EXERCISE_CONFIG[random_key]

	var scene = load(config).instantiate()
	scene.initialize()
	parent.get_node("QuestionsContainer").add_child(scene)
	
	current_question = scene
	parent.question_count += 1
	parent.timeout_occurred = false
	
	setup_exercise_signals()
	parent.ui_manager.update_question_count(parent.question_count)
	parent.timer_manager.start_timer_for_exercise(current_exercise_type)
	parent.ui_manager.set_random_background("fade")

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
