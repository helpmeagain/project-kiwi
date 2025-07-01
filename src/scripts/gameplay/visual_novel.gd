extends Control

var current_exercise: Node = null
var current_next_timeline: String = ""
var current_exercise_id: String = ""
var exercise_config: Dictionary

func _ready() -> void:
	exercise_config = load_exercise_config()
	Dialogic.signal_event.connect(_on_dialogic_signal)
	start_dialogic_timeline("chapter-1")

func _on_dialogic_signal(argument: String):
	if argument.begins_with("bg_"):
		var parts = argument.split(",")
		var bg_name = parts[0].trim_prefix("bg_")
		var transition = parts[1] if parts.size() > 1 else "fade"
		set_background(bg_name, transition)
	if argument.contains("end-game"):
		$EndGameControl.show()
	if exercise_config.has(argument):
		setup_exercise(argument)

func setup_exercise(exercise_key: String) -> void:
	var config: Dictionary = exercise_config[exercise_key]
	
	current_exercise_id = config.data.id
	current_exercise = load(config.scene).instantiate()
	current_next_timeline = config.get("next_timeline", "")
	
	if current_exercise.has_method("initialize"):
		current_exercise.initialize(config.data.file, config.data.id)
	
	_connect_exercise_signals(current_exercise)
	$QuestionsControl.add_child(current_exercise)

func set_background(background_name: String, transition_type: String = "fade") -> void:
	var extensions = [".png", ".jpg", ".jpeg"]
	var bg_path := ""
	var new_texture: Texture2D = null
	
	for ext in extensions:
		var try_path = "res://src/assets/backgrounds/%s%s" % [background_name, ext]
		if ResourceLoader.exists(try_path):
			bg_path = try_path
			new_texture = load(bg_path)
			break
	
	if new_texture:
		$BackgroundControl/ImageBackground.change_background(new_texture, transition_type)
	else:
		push_error("Background not found with supported extensions for: " + background_name)
	
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
	$QuestionsControl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$WrongAnswer.show()
	var correct = _get_correct_answer_from_json("res://src/assets/exercises/" + exercise_config[current_exercise_id].data.file)
	$WrongAnswer/WrongPanel/VBoxContainer/Subtitle.text = "Resposta correta: " + correct

func _cleanup_exercise():
		$QuestionsControl.remove_child(current_exercise)
		current_exercise.queue_free()
		current_exercise = null
		current_next_timeline = ""

func start_dialogic_timeline(timeline: String) -> void:
	Dialogic.start(timeline)

func _on_wrong_panel_button_pressed() -> void:
	$WrongAnswer.hide()
	$QuestionsControl.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_start_game_button_pressed() -> void:
	$StartGameControl.hide()
	start_dialogic_timeline("introduction")

func _on_end_game_button_pressed() -> void:
		get_tree().change_scene_to_file("res://src/scenes/menus/singleplayer-menu.tscn")

func _get_correct_answer_from_json(path_to_json: String) -> String:
	var file = FileAccess.open(path_to_json, FileAccess.READ)
	if file == null:
		push_error("Não conseguiu abrir: " + path_to_json)
		return ""
	
	var j = JSON.new()
	var err = j.parse(file.get_as_text())
	if err != OK:
		push_error("JSON Parse Error: %s" % j.get_error_message())
		return ""
	
	var data = j.get_data()
	for entry in data:
		if typeof(entry) == TYPE_DICTIONARY and entry.get("id", "") == current_exercise_id:
			if entry.has("correct_answer"):
				return entry.get("correct_answer", "")
			elif entry.has("correct_answers"):
				var arr = entry.get("correct_answers", [])
				if arr.size() > 0:
					return arr[0]
	return ""
