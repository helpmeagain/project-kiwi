extends Node2D

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.start("school-entrance")
	
func _on_dialogic_signal(argument: String):
	match argument:
		"type_sentence":
			var cena = preload("res://src/scenes/exercises/type-the-sentence.tscn").instantiate()
			cena.initialize()
			$QuestionsContainer.add_child(cena)
		"listen_type":
			var cena = preload("res://src/scenes/exercises/listen-then-type.tscn").instantiate()
			cena.initialize()
			$QuestionsContainer.add_child(cena)
		"fill_blank":
			var cena = preload("res://src/scenes/exercises/fill-in-the-blank.tscn").instantiate()
			cena.initialize()
			$QuestionsContainer.add_child(cena)
