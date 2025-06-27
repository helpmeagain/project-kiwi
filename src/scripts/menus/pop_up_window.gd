extends Window

@onready var simbol_label: Label = $HBoxContainer/Warning
@onready var message_label: Label = $HBoxContainer/WindowLabel

func show_error(message: String):
	self.title = "Error"
	message_label.text = message
	print("[DEBUG] " + message)
	if not self.is_inside_tree():
		get_tree().root.add_child(self)
	self.popup_centered()

func _on_close_requested() -> void:
	self.hide()
