extends Control

@onready var player_list = $PlayerInformationTable/ScrollContainer/PlayerListBoxContainer

func _ready():
	MultiplayerPlayerManager.scores_updated.connect(update_player_list)
	update_player_list()

func update_player_list():
	# Limpa a lista atual
	for child in player_list.get_children():
		child.queue_free()
	
	# Ordena jogadores
	var players_array = MultiplayerPlayerManager.players.values()
	players_array.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# Cria linhas da tabela
	for player in players_array:
		var row = HBoxContainer.new()  # Container para cada linha
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Label do nome
		var name_label = Label.new()
		name_label.text = player["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.custom_minimum_size.x = 200  # Largura fixa para a coluna de nomes
		
		# Label da pontuação
		var score_label = Label.new()
		score_label.text = str(player["score"]) + " pontos"
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		score_label.custom_minimum_size.x = 100  # Largura fixa para a coluna de pontos
		
		# Adiciona à linha
		row.add_child(name_label)
		row.add_child(score_label)
		player_list.add_child(row)
