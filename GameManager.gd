extends Node
var selected_ship_type = "default"  # Default starting selection


var player_types = {
	"Bomber": {
		"description": "Bomber - Fast top speed but with poor maneuverability and main firepower,
						it's main strength comes from its ability to fire a volley of missiles often.",
		"animation_frames": preload("res://interceptor1.tres")
	},
	"Cross_Wing": {
		"description": "A starfighter",
		"animation_frames": preload("res://xwingv1.tres")
	},
	"Pi_Fighter": {
		"description": "A highly maneuverable dog-fighter. 
						Slower top speed but fast acceleration and banking. 
						Reducing power budget for shields allows greater firepower for main guns, 
						but the lack of a targetting droid means missiles take longer to recharge.",
		"animation_frames": preload("res://fighter1.tres")
	}
}

func start_game():
	get_tree().change_scene_to_file("res://asteroided.tscn")

func return_to_menu():
	get_tree().change_scene_to_file("res://StartMenu.tscn")

var score: int = 0  # Stores total player points

func add_score(amount):
	score += amount
