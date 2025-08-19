class_name UIControl
extends Control

signal start_multiplayer_exercise

const COUNTDOWN_DEFAULT_VALUE = 3
var max_questions: int = 0
var matchmaking_countdown: int = COUNTDOWN_DEFAULT_VALUE

func update_question_count(count: int) -> void:
	$QuestionCountLabel.text = str(count) + "/" + str(max_questions)

func update_score(score: int) -> void:
	$ScoreLabel.text = "Score = " + str(score)

func update_timer_label(time_left: float) -> void:
	$TimerLabel.text = str(int(time_left)) + "s"

func update_all_ui_components(score: int, question_count: int, is_double_points_active: bool, is_extra_chance_active: bool) -> void:
	update_score(score)
	update_question_count(question_count)
	update_powerup_icons(is_double_points_active, is_extra_chance_active)
	$PartnerAnswerLabel.hide()

func update_powerup_icons(is_double_points_active: bool, is_extra_chance_active: bool) -> void:	
	$PowerUpContainer/DoublePointsIcon.visible = is_double_points_active
	$PowerUpContainer/ExtraChanceIcon.visible = is_extra_chance_active

func show_matchmaking_screen() -> void:
	$MatchmakingControl/MultiplayerWarningLabel.text = "A próxima questão será jogada em dupla!"
	$MatchmakingControl/MatchmakingLabel.text = "Procurando outro jogador..."
	$TimerLabel.hide()
	$QuestionCountLabel.hide()
	$MatchmakingControl/LoadingSprite.play()
	$MatchmakingControl/LoadingSprite.show()
	$MatchmakingControl.show()
	matchmaking_countdown = COUNTDOWN_DEFAULT_VALUE

func hide_matchmaking_screen() -> void:
	$MatchmakingControl/LoadingSprite.stop()
	$TimerLabel.show()
	$QuestionCountLabel.show()
	$MatchmakingControl.hide()

func update_partner_found(partner_name: String) -> void:
	$MatchmakingControl/MultiplayerWarningLabel.text = "Encontrou " + partner_name + "!"
	$MatchmakingControl/MatchmakingLabel.text = "Iniciando em " + str(matchmaking_countdown) + "..."
	$MatchmakingControl/MatchmakingTimer.start()
	$MatchmakingControl/LoadingSprite.stop()
	$MatchmakingControl/LoadingSprite.hide()

func _on_matchmaking_timer_timeout() -> void:
	matchmaking_countdown -= 1
	if matchmaking_countdown > 0:
		$MatchmakingControl/MatchmakingLabel.text = "Iniciando em " + str(matchmaking_countdown) + "..."
	else:
		$MatchmakingControl/MatchmakingTimer.stop()
		$MatchmakingControl.hide()
		$TimerLabel.show()
		$QuestionCountLabel.show()
		emit_signal("start_multiplayer_exercise")
	
func hide_leaderboard() -> void:
	$ShowPlayersButton.hide()
