class_name UIControl
extends Control

var max_questions: int = 0

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

func update_powerup_icons(is_double_points_active: bool, is_extra_chance_active: bool) -> void:	
	$PowerUpContainer/DoublePointsIcon.visible = is_double_points_active
	$PowerUpContainer/ExtraChanceIcon.visible = is_extra_chance_active
