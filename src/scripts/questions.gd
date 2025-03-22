extends Control

const EXERCISE_CONFIG = {
	"fill_in_blank": {
		"scene": "res://src/scenes/exercises/fill-in-the-blank.tscn",
		"data_file": "fill_in_the_blank.json"
	},
#	"listen_then_type": {
#		"scene": "res://src/scenes/exercises/listen-then-type.tscn",
#		"data_file": "listen_then_type.json"
#	},
	"type_translation": {
		"scene": "res://src/scenes/exercises/type-the-sentence.tscn",
		"data_file": "type-the-sentence.json"
	}
}

const SCORE_TEXT = "Score = "
var current_question: Node
var score: int

func _ready() -> void:
	score = 0
	$ScoreLabel.text = SCORE_TEXT + str(score)
	load_random_question()

func load_random_question() -> void:
	if current_question:
		current_question.queue_free()
	
	var exercise_keys = EXERCISE_CONFIG.keys()
	var random_key = exercise_keys[randi() % exercise_keys.size()]
	var config = EXERCISE_CONFIG[random_key]
	
	var scene = load(config.scene).instantiate()
	scene.initialize(config.data_file)
	add_child(scene)
	
	current_question = scene
	
	if current_question.has_signal("answer_correct"):
		current_question.connect("answer_correct", _on_answer_correct)
	if current_question.has_signal("answer_wrong"):
		current_question.connect("answer_wrong", _on_answer_wrong)

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
