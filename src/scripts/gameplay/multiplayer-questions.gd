extends Control

const EXERCISE_CONFIG = {
	"fill_in_blank": "res://src/scenes/exercises/fill-in-the-blank.tscn",
	"listen_then_type": "res://src/scenes/exercises/listen-then-type.tscn",
	"type_translation": "res://src/scenes/exercises/type-the-sentence.tscn"
}
const SCORE_TEXT = "Score = "
const MAX_QUESTIONS = 3

var current_question: Node
var score: int
var question_count: int

func _ready() -> void:
	score = 0
	question_count = 0
	$QuestionCountLabel.text = str(question_count) + "/" + str(MAX_QUESTIONS)
	$ScoreLabel.text = SCORE_TEXT + str(score)
	load_random_question()

func load_random_question() -> void:
	if question_count >= MAX_QUESTIONS:
		show_final_screen()
		return
	
	if current_question:
		current_question.queue_free()
	
	var exercise_keys = EXERCISE_CONFIG.keys()
	var random_key = exercise_keys[randi() % exercise_keys.size()]
	var config = EXERCISE_CONFIG[random_key]

	var scene = load(config).instantiate()
	scene.initialize()
	$QuestionsContainer.add_child(scene)
	
	current_question = scene
	question_count += 1
	$QuestionCountLabel.text = str(question_count) + "/" + str(MAX_QUESTIONS)
	
	if current_question.has_signal("answer_correct"):
		current_question.connect("answer_correct", _on_answer_correct)
	if current_question.has_signal("answer_wrong"):
		current_question.connect("answer_wrong", _on_answer_wrong)
		
func show_final_screen() -> void:
	$FinalLabel.text = "Game over! Score: " + str(score)
	$FinalLabel.show()
	$ScoreLabel.hide()
	$QuestionCountLabel.hide()
	$ShowPlayersButton.hide()
	$"Player-score".set_position(Vector2(450, 200))
	$"Player-score".show()
	if current_question:
		current_question.queue_free()

func _on_answer_correct() -> void:
	score += 1
	if multiplayer.is_server():
		MultiplayerPlayerManager.players[multiplayer.get_unique_id()]["score"] = score
		MultiplayerPlayerManager.update_player_score.rpc(multiplayer.get_unique_id(), score)
	else:
		MultiplayerPlayerManager.request_update_score.rpc_id(1, multiplayer.get_unique_id(), score)
	update_score_display()
	load_random_question()

func _on_answer_wrong() -> void:
	update_score_display()
	load_random_question()

func update_score_display() -> void:
	$ScoreLabel.text = SCORE_TEXT + str(score)

func _on_show_players_button_pressed() -> void:
	$"Player-score".visible = not $"Player-score".visible
