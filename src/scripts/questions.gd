extends Control

const SCORE_TEXT = "Score = "
var correct_button: int
var score: int

func _ready() -> void:
	score = 0
	$ScoreLabel.text = SCORE_TEXT + str(score)
	randomize()
	choose_new_button()

func choose_new_button() -> void:
	correct_button = randi() % 4 + 1
	print("New button:", correct_button)

func _on_button_pressed(button_number: int) -> void:
	if button_number == correct_button:
		score += 1
		$ColorRect.color = Color.GREEN
		$ScoreLabel.text = SCORE_TEXT + str(score)
		choose_new_button()
		if multiplayer.is_server():
			MultiplayerPlayerManager.players[multiplayer.get_unique_id()]["score"] = score
			MultiplayerPlayerManager.update_player_score.rpc(multiplayer.get_unique_id(), score)
		else:
			MultiplayerPlayerManager.request_update_score.rpc_id(1, multiplayer.get_unique_id(), score)
	else:
		$ColorRect.color = Color.RED
	$ColorRect/ColorTimer.start()

func _on_timer_timeout() -> void:
	$ColorRect.color = Color.WHITE

func _on_button_1_pressed() -> void:
	_on_button_pressed(1)

func _on_button_2_pressed() -> void:
	_on_button_pressed(2)
	
func _on_button_3_pressed() -> void:
	_on_button_pressed(3)

func _on_button_4_pressed() -> void:
	_on_button_pressed(4)
