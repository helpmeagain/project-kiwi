class_name TimerManager
extends Node

# Configurações
const QUICKER_TIME = 15
const DEFAULT_TIME = 25

# Referências
var parent: Control

func _init(parent_node: Control) -> void:
	parent = parent_node

func start_timer_for_exercise(exercise_type: String) -> void:
	var timer = parent.get_node("Timer")
	
	if exercise_type == "fill_in_blank" or "vocabulary":
		timer.wait_time = QUICKER_TIME
	else:
		timer.wait_time = DEFAULT_TIME
	
	timer.start()

func stop_timer() -> void:
	parent.get_node("Timer").stop()

func get_time_left() -> float:
	return parent.get_node("Timer").time_left
