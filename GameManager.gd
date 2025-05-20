extends Node
var selected_username = "" #Track logged-in user
var selected_ship_type = "default"  # Default starting selection
var lifetime_score: int = 0  # Holds score before adding to total balance
var total_score: int = 0

var user_profiles = {}  # Store profiles globally for access in all scenes

var player_types = {
	"Bomber": {
		"description": "Bomber - Fast top speed but with poor maneuverability and main firepower,
						it's main strength comes from its ability to fire a volley of missiles often.",
		"animation_frames": preload("res://Anim_frames/interceptor1.tres")
	},
	"Cross_Wing": {
		"description": "Jack of all trades - 
						fast special reload, decent fire-rate, average health, and highly accurate.",
		"animation_frames": preload("res://Anim_frames/xwingv1.tres")
	},
	"Pi_Fighter": {
		"description": "A highly maneuverable dog-fighter. 
						Slower top speed but fast acceleration and banking. 
						Reducing power budget for shields allows greater firepower for main guns, 
						but the lack of a targetting droid means missiles take longer to recharge.",
		"animation_frames": preload("res://Anim_frames/fighter1.tres")
	}
}

func _ready():
	load_profiles()

func start_game():
	get_tree().change_scene_to_file("res://asteroided.tscn")

func return_to_menu():
	get_tree().change_scene_to_file("res://StartMenu.tscn")

func load_profiles():
	var file = FileAccess.open("user_profiles.json", FileAccess.READ)
	if file:
		GameManager.user_profiles = JSON.parse_string(file.get_as_text())
		file.close()
		print("Loaded user profiles:", GameManager.user_profiles)  # Debug output
	else:
		print("Failed to load profiles!")

func add_score(amount):
	lifetime_score += amount
	total_score += amount  
	print(selected_username)
	# Check if username exists before updating
	if selected_username in user_profiles:
		print("Updating points for:", selected_username)
		print("Previous points:", user_profiles[selected_username]["points"])
		user_profiles[selected_username]["points"] = total_score
		print("Updated points:", user_profiles[selected_username]["points"])
		save_profiles()
	else:
		print("User not found in profiles!")

	# Introduce a random enemy spawn chance
	var spawn_chance = clamp(amount / 50.0, 0.05, 0.3)
	if randf() < spawn_chance:
		get_node("/root/Asteroided").spawn_random_enemy()

func save_profiles():
	var json_data = JSON.stringify(user_profiles, "\t")  # Pretty-printing for readability
	var file = FileAccess.open("user_profiles.json", FileAccess.WRITE)
	if file:
		print("Saving profiles:", json_data)  # Debug message to confirm file saving
		file.store_string(json_data)
		file.close()
	else:
		print("Failed to open file for writing!")

func handle_death():
	get_tree().change_scene_to_file("res://DeathScreen.tscn")  # Transition to death screen
