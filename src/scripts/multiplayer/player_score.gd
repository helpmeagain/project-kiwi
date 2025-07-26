extends Control

@onready var player_list = $Panel/PlayerInformationTable/ScrollContainer/PlayerListGridContainer
var multiplayer_control: MultiplayerControl

func set_multiplayer_control(control: MultiplayerControl) -> void:
	multiplayer_control = control
	multiplayer_control.leaderboard_updated.connect(update_leaderboard)

func update_leaderboard(records: Array) -> void:
	for child in player_list.get_children():
		child.queue_free()
	
	for record in records:
		var name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.custom_minimum_size.x = 150
		name_label.clip_text = true
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		
		var font = name_label.get_theme_font("font")
		var max_width = name_label.custom_minimum_size.x
		name_label.text = truncate_text(record.username, font, max_width)
		
		var score_label = Label.new()
		var score_value = int(record.score)
		score_label.text = (str(score_value) if score_value != 0 else "0") + " pontos"
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		score_label.custom_minimum_size.x = 100
		
		player_list.add_child(name_label)
		player_list.add_child(score_label)

func truncate_text(text: String, font: Font, max_width: float) -> String:
	var ellipsis = "..."
	
	if font.get_string_size(text).x <= max_width:
		return text
	
	var truncated = text
	while font.get_string_size(truncated + ellipsis).x > max_width and truncated.length() > 0:
		truncated = truncated.substr(0, truncated.length() - 1)
	
	return truncated + ellipsis
