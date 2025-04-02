extends Control

@onready var player_list = $Panel/PlayerInformationTable/ScrollContainer/PlayerListGridContainer

func _ready():
	MultiplayerPlayerManager.scores_updated.connect(update_player_list)
	update_player_list()

func update_player_list():
	for child in player_list.get_children():
		child.queue_free()
	
	var players_array = MultiplayerPlayerManager.players.values()
	players_array.sort_custom(func(a, b): return a["score"] > b["score"])
	
	for player in players_array:
		var name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.custom_minimum_size.x = 150
		name_label.clip_text = true
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		
		var font = name_label.get_theme_font("font")
		var max_width = name_label.custom_minimum_size.x
		name_label.text = truncate_text(player["name"], font, max_width)
		
		var score_label = Label.new()
		score_label.text = str(player["score"]) + " pontos"
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
