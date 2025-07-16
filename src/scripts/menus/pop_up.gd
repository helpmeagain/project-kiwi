class_name PopupManager
extends Control

signal ok_pressed

var title_label: Label
var subtitle_label: Label
var ok_button: Button

static var _instance: PopupManager = null
static func instance() -> PopupManager:
	if _instance == null:
		_instance = load("res://src/scenes/menus/pop-up.tscn").instantiate()
		Engine.get_main_loop().root.add_child(_instance)
		_instance.set_as_top_level(true)
		_instance.hide()
		_instance.title_label = _instance.get_node("PopupPanel/VBoxContainer/Title")
		_instance.subtitle_label = _instance.get_node("PopupPanel/VBoxContainer/Subtitle")
		_instance.ok_button = _instance.get_node("PopupPanel/OkButton")
	return _instance

func _setup_popup(title: String, subtitle: String, shadow_color: Color = Color("DIM_GRAY"), show_button: bool = true) -> void:
	title_label.add_theme_color_override("font_shadow_color", shadow_color)
	title_label.text = title
	subtitle_label.text = subtitle
	if show_button:
		ok_button.show()
	else:
		ok_button.hide()
	show()

static func show_wrong_answer(correct_answer: String) -> void:
	instance()._setup_popup("Wrong answer!", "Correct answer was: \n" + correct_answer, Color("RED"))
	
static func show_congratulations_answer(correct_answer: String) -> void:
	instance()._setup_popup("Correct answer!", "Correct answer was: \n" + correct_answer, Color("GREEN"))
	
static func show_timeout_message(correct_answer: String) -> void:
	instance()._setup_popup("Time's Up!", "Correct answer was: \n" + correct_answer, Color("ORANGE"))
	
static func show_error(message: String) -> void:
	instance()._setup_popup("Error!", message, Color("RED"))

static func show_warning(message: String) -> void:
	instance()._setup_popup("Warning!", message, Color("YELLOW"))

static func show_success(message: String) -> void:
	instance()._setup_popup("Success!", message, Color("GREEN"))
	
static func show_connecting() -> void:
	instance()._setup_popup("Connecting...", "Trying to connect to the server. Do not close the game or turn off your device.", Color("DIM_GRAY"), false)

static func show_custom(title: String, message: String, color: Color = Color("DIM_GRAY"), show_button: bool = true) -> void:
	instance()._setup_popup(title, message, color, show_button)

func _on_ok_button_pressed() -> void:
	emit_signal("ok_pressed")
	hide()
	queue_free()
