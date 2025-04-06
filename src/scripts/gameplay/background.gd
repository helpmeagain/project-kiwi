extends TextureRect

signal transition_started()
signal transition_finished()

var current_texture: Texture
var next_texture: Texture
var transition_duration: float = 3.0
var transition_progress: float = 0.0
var is_transitioning: bool = false
var transition_type: String = "fade"

func _ready() -> void:
	current_texture = texture
	modulate.a = 1.0

func change_background(new_texture: Texture, new_transition_type: String = "fade") -> void:
	if is_transitioning or new_texture == current_texture:
		return
	
	next_texture = new_texture
	transition_type = new_transition_type
	transition_progress = 0.0
	is_transitioning = true
	emit_signal("transition_started")
	set_process(true)

func _process(delta: float) -> void:
	if not is_transitioning:
		return
	
	transition_progress += delta / transition_duration
	
	match transition_type:
		"fade":
			_process_fade_transition()
		"slide_left":
			_process_slide_left_transition()
	
	if transition_progress >= 1.0:
		_finish_transition()

func _process_fade_transition() -> void:
	var fade_value = ease(transition_progress, 0.5)
	modulate.a = 1.0 - fade_value
	
	if fade_value >= 0.5 and texture != next_texture:
		texture = next_texture
		modulate.a = 0.0

	if texture == next_texture:
		modulate.a = (fade_value - 0.5) * 2.0

func _process_slide_left_transition() -> void:
	position.x = -size.x * transition_progress
	if transition_progress >= 0.5 and texture != next_texture:
		texture = next_texture
		position.x = size.x * (1.0 - transition_progress)

func _finish_transition() -> void:
	transition_progress = 0.0
	is_transitioning = false
	current_texture = next_texture
	next_texture = null
	modulate.a = 1.0
	set_process(false)
	emit_signal("transition_finished")
