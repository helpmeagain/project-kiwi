extends Control

var current_exercise: Node = null
var current_next_timeline: String = ""
var exercise_config: Dictionary

func _ready() -> void:
	exercise_config = load_exercise_config()
	Dialogic.signal_event.connect(_on_dialogic_signal)
	start_dialogic_timeline("school-entrance")

func _on_dialogic_signal(argument: String):
	if exercise_config.has(argument):
		setup_exercise(argument)

func setup_exercise(exercise_key: String) -> void:
	var config: Dictionary = exercise_config[exercise_key]
	
	current_exercise = load(config.scene).instantiate()
	current_next_timeline = config.get("next_timeline", "")
	
	if current_exercise.has_method("initialize"):
		current_exercise.initialize(config.data.file, config.data.id)
	
	_connect_exercise_signals(current_exercise)
	$QuestionsContainer.add_child(current_exercise)
	
func load_exercise_config() -> Dictionary:
	var config_file = FileAccess.open("res://src/assets/exercises/story-exercises-config.json", FileAccess.READ)
	if config_file:
		var json = JSON.new()
		var error = json.parse(config_file.get_as_text())
		if error == OK:
			return json.data
		else:
			push_error("JSON Parse Error: %s at line %s" % [json.get_error_message(), json.get_error_line()])
	return {}

func _connect_exercise_signals(exercise_node: Node) -> void:
	exercise_node.connect("answer_correct", _on_answer_correct)
	exercise_node.connect("answer_wrong", _on_answer_wrong)

func _on_answer_correct():
	Dialogic.VAR.correct_answer += 1
	var next_timeline = current_next_timeline
	_cleanup_exercise()
	if next_timeline:
		start_dialogic_timeline(next_timeline)

func _on_answer_wrong():
	Dialogic.VAR.wrong_answer += 1
	$QuestionsContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$BlackScreen.show()
	$WrongPanel.show()

func _cleanup_exercise():
	if current_exercise:
		$QuestionsContainer.remove_child(current_exercise)
		current_exercise.queue_free()
		current_exercise = null
		current_next_timeline = ""

func start_dialogic_timeline(timeline: String) -> void:
	Dialogic.start(timeline)

func _on_wrong_panel_button_pressed() -> void:
	$QuestionsContainer.mouse_filter = Control.MOUSE_FILTER_STOP
	$BlackScreen.hide()
	$WrongPanel.hide()
