extends Node
var selected_username = "" #Track logged-in user
var selected_ship_type = "default"  # Default starting selection
var lifetime_score: int = 0  # Holds score before adding to total balance
var total_score: int = 0
var selected_missiles = []

var user_profiles = {}  # Store profiles globally for access in all scenes

var missile_types = {
	"default_missile": {
		"turn_speed": 1,
		"speed": 4000,
		"range": 16000,
		"damage": 50,
		"explosion_radius": 500,
		"description": "A basic air-to-air missile with balanced stats. Reliable in most situations."
	},
	"AIM-120": { # AMRAAM
		"turn_speed": 1,
		"speed": 4000,
		"range": 16000,
		"damage": 50,
		"explosion_radius": 500,
		"description": "Advanced medium-range missile with radar guidance, ideal for engaging targets beyond visual range."
	},
	"AIM-9X": { # Sidewinder
		"turn_speed": 3,
		"speed": 2500,
		"range": 3500,
		"damage": 21,
		"explosion_radius": 210,
		"description": "Short-range heat-seeking missile with high agility—perfect for dogfights."
	},
	"AIM-132": { # ASRAAM
		"turn_speed": 4,
		"speed": 3000,
		"range": 2500,
		"damage": 22,
		"explosion_radius": 220,
		"description": "A British-built short-range missile optimized for rapid engagement and high-speed interception."
	},
	"R-77": { # Russian equivalent of AIM-120
		"turn_speed": .5,
		"speed": 3000,
		"range": 8000,
		"damage": 40,
		"explosion_radius": 320,
		"description": "A Russian-built radar-guided missile known for its excellent range and strong lethality."
	},
	"AIM-54": { # Phoenix, long-range air-to-air missile
		"turn_speed": 1,
		"speed": 4500,
		"range": 19000,
		"damage": 60,
		"explosion_radius": 550,
		"description": "A long-range missile designed for high-speed aerial engagements, best suited for large threats."
	},
	"IRIS-T": { # Highly maneuverable short-range heat-seeker
		"turn_speed": 5,
		"speed": 2800,
		"range": 3500,
		"damage": 24,
		"explosion_radius": 230,
		"description": "Extremely agile infrared-guided missile, ideal for close-range battles and defensive tactics."
	}
}

var player_types = {
	"Bomber": {
		"description": "High speed bomber - High health, top speed, and able to fire a volley of missiles,
		but slow to maneuver and accelerate and slow fire rate.",
		"animation_frames": preload("res://Anim_frames/interceptor1.tres"),
		"bullet_scene": preload("res://bullet.tscn"),
		"special_scenes": [
			"AIM-120", "AIM-9X", "AIM-132"
		],
		"collision_scale": 4,
		"sprite_scale": 4,
		"max_speed": 1300,
		"rotation_speed": 0.05,
		"max_bank_angle": 13,
		"accel": 6,
		"drag": 4,
		"max_health": 300,
		"fire_rate": 2,
		"special_cooldown": 2,
		"bullet_velocity": 2500,
		"bullet_damage": 20,
		"bullet_range": 2500,
		"bullet_spread": 0.02,
		"bullet_radius": 200
	},
	"Cross_Wing": {
		"description": "Jack of all trades - fast special reload, decent fire-rate, average health, and highly accurate.",
		"animation_frames": preload("res://Anim_frames/xwingv1.tres"),
		"bullet_scene": preload("res://bullet.tscn"),
		"special_scenes": [
			"AIM-120", "AIM-9X"
		],
		"collision_scale": 3,
		"sprite_scale": 3,
		"max_speed": 900,
		"rotation_speed": 0.25,
		"max_bank_angle": 10,
		"accel": 15,
		"drag": 6,
		"max_health": 150,
		"fire_rate": 20,
		"special_cooldown": 4,
		"bullet_velocity": 4000,
		"bullet_damage": 15,
		"bullet_range": 3000,
		"bullet_spread": 0.03,
		"bullet_radius": 100
	},
	"Pi_Fighter": {
		"description": "A highly maneuverable dog-fighter. Slower top speed but fast acceleration and banking. 
		Reducing power budget for shields allows greater firepower for main guns, 
		but the lack of a targeting droid means missiles take longer to recharge.",
		"animation_frames": preload("res://Anim_frames/fighter1.tres"),
		"bullet_scene": preload("res://bullet.tscn"),
		"special_scenes": [
			"AIM-9X"
		],
		"collision_scale": 2,
		"sprite_scale": 2,
		"max_speed": 700,
		"rotation_speed": 0.2,
		"max_bank_angle": 15,
		"accel": 25,
		"drag": 8,
		"max_health": 100,
		"fire_rate": 20,
		"special_cooldown": 10,
		"bullet_velocity": 4000,
		"bullet_damage": 20,
		"bullet_range": 2000,
		"bullet_spread": 0.1,
		"bullet_radius": 150
	}
}

var enemy_data = {
	"fighter1": {
		"animation_frames": preload("res://Anim_frames/fighter1.tres"),
		"speed": 500,
		"turn_radius": 3, #How quickly fighter turns turns
		"weapon_scene": preload("res://bullet.tscn"),
		"bullet_velocity": 1200,
		"bullet_damage": 15,
		"bullet_range": 1500,
		"bullet_explosion_radius": 80,
		"fire_rate": 1.0, #Time between shots
		"max_health": 50,
		"targeting_range" : 1500,
		"enemy_type" : "fighter"
	},
	"interceptor1": {
		"animation_frames": preload("res://Anim_frames/interceptor1.tres"),
		"speed": 1000,
		"turn_radius": 1,
		"weapon_scene": preload("res://bullet.tscn"),
		"bullet_velocity": 1600,
		"bullet_damage": 25,
		"bullet_range": 10000,
		"bullet_explosion_radius": 160,
		"fire_rate": 6,
		"max_health": 300,
		"targeting_range" : 10000,
		"enemy_type" : "bomber"
	},
	"fighter2": {
		"animation_frames": preload("res://Anim_frames/xwingv1.tres"),
		"speed": 750,
		"turn_radius": 2,
		"weapon_scene": preload("res://bullet.tscn"),
		"bullet_velocity": 1500,
		"bullet_damage": 15,
		"bullet_range": 2500,
		"bullet_explosion_radius": 60,
		"fire_rate": .5,
		"max_health": 100,
		"targeting_range" : 2500,
		"enemy_type" : "fighter"
	}
}


func _ready():
	load_profiles()

func start_game():
	get_tree().change_scene_to_file("res://asteroided.tscn")

func return_to_menu():
	get_tree().change_scene_to_file("res://StartMenu.tscn")
	
func loadout_menu():
	get_tree().change_scene_to_file("res://LoadoutMenu.tscn")

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
	if selected_username in user_profiles:
		user_profiles[selected_username]["points"] = total_score
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
		file.store_string(json_data)
		file.close()
	else:
		print("Failed to open file for writing!")

func handle_death():
	get_tree().change_scene_to_file("res://DeathScreen.tscn")  # Transition to death screen
