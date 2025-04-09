extends Node

func start_game():
	get_tree().change_scene_to_file("res://asteroided.tscn")

func return_to_menu():
	get_tree().change_scene_to_file("res://StartMenu.tscn")

var score: int = 0  # Stores total player points

func add_score(amount):
	score += amount
