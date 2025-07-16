class_name SaveManager
extends Resource

const SAVE_PATH := "user://save_games.tres"

@export var singleplayer_score := 0
@export var singleplayer_question_count := 0
@export var singleplayer_highscore := 0
@export var singleplayer_extra_life_active := false
@export var singleplayer_double_points_active := false

@export var multiplayer_score := 0
@export var multiplayer_question_count := 0
@export var multiplayer_highscore := 0
@export var multiplayer_double_points_active := false
@export var multiplayer_extra_life_active := false

static func save_session(is_multiplayer: bool, score: int, question_count: int, double_points_active: bool, extra_live_active: bool):
	var save_data = _load_or_create_save()
	
	if is_multiplayer:
		save_data.multiplayer_score = score
		save_data.multiplayer_question_count = question_count
		save_data.multiplayer_extra_life_active = extra_live_active
		save_data.multiplayer_double_points_active = double_points_active
	else:
		save_data.singleplayer_score = score
		save_data.singleplayer_question_count = question_count
		save_data.singleplayer_double_points_active = double_points_active
		save_data.singleplayer_extra_life_active = extra_live_active
	
	ResourceSaver.save(save_data, SAVE_PATH)

static func load_session(is_multiplayer: bool) -> Dictionary:
	var save_data = _load_or_create_save()
	
	if is_multiplayer:
		return {
			"score": save_data.multiplayer_score,
			"question_count": save_data.multiplayer_question_count,
			"highscore": save_data.multiplayer_highscore,
			"double_points_active": save_data.singleplayer_double_points_active,
			"extra_life_active": save_data.multiplayer_extra_life_active,
		}
	else:
		return {
			"score": save_data.singleplayer_score,
			"question_count": save_data.singleplayer_question_count,
			"highscore": save_data.singleplayer_highscore,
			"double_points_active": save_data.singleplayer_double_points_active,
			"extra_life_active": save_data.singleplayer_extra_life_active,
		}


static func finish_session(is_multiplayer: bool, new_score: int):
	var save_data = _load_or_create_save()
	
	if is_multiplayer:
		save_data.multiplayer_score = 0
		save_data.multiplayer_question_count = 0
		save_data.multiplayer_double_points_active = false
		save_data.multiplayer_extra_life_active = false
		if new_score > save_data.multiplayer_highscore:
			save_data.multiplayer_highscore = new_score
	else:
		save_data.singleplayer_score = 0
		save_data.singleplayer_question_count = 0
		save_data.singleplayer_double_points_active = false
		save_data.singleplayer_extra_life_active = false
		if new_score > save_data.singleplayer_highscore:
			save_data.singleplayer_highscore = new_score
	
	ResourceSaver.save(save_data, SAVE_PATH)
	
static func get_highscore(is_multiplayer: bool) -> int:
	var save_data = _load_or_create_save()
	return save_data.multiplayer_highscore if is_multiplayer else save_data.singleplayer_highscore

static func _load_or_create_save() -> SaveManager:
	if ResourceLoader.exists(SAVE_PATH):
		return ResourceLoader.load(SAVE_PATH) as SaveManager
	else:
		return SaveManager.new()
