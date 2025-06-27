class_name PowerUpManager
extends Node

# Estado
var double_points_active := false
var extra_life_active := false
var extra_life_used := false

# Referências
var parent: Control

func _init(parent_node: Control) -> void:
	parent = parent_node

func reset() -> void:
	double_points_active = false
	extra_life_active = false
	extra_life_used = false

func get_score_multiplier() -> int:
	return 2 if double_points_active else 1

func activate_double_points() -> void:
	double_points_active = true

func deactivate_double_points() -> void:
	double_points_active = false

func activate_extra_life() -> void:
	extra_life_active = true
	extra_life_used = false

func use_extra_life() -> bool:
	if extra_life_active and not extra_life_used:
		extra_life_used = true
		extra_life_active = false
		return true
	return false
