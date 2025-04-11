extends Node2D

var enemy_data = {
	"fighter1": {
		"animation_frames": preload("res://fighter1.tres"),
		"speed": 500,
		"turn_radius": 3, #How quickly fighter turns turns
		"weapon_scene": preload("res://bullet.tscn"),
		"bullet_velocity": 1200,
		"bullet_damage": 15,
		"bullet_range": 1200,
		"bullet_explosion_radius": 80,
		"fire_rate": 1.0, #Time between shots
		"max_health": 100,
		"targeting_range" : 1000
	},
	"interceptor1": {
		"animation_frames": preload("res://interceptor1.tres"),
		"speed": 1000,
		"turn_radius": 1,
		"weapon_scene": preload("res://Missile.tscn"),
		"bullet_velocity": 1000,
		"bullet_damage": 25,
		"bullet_range": 5000,
		"bullet_explosion_radius": 160,
		"fire_rate": 4,
		"max_health": 200,
		"targeting_range" : 2000
	}
}

var spawn_area = Rect2(300, 300, 1200, 800)  # Move closer to player view
var enemy_scene = preload("res://enemy.tscn")

var enemy_count = 0
var max_enemies = 10  # Adjust based on desired difficulty
var respawn_min_time = 2.0  # Minimum respawn delay
var respawn_max_time = 6.0  # Maximum respawn delay

func enemy_destroyed():
	enemy_count - 1
	check_respawn()
	
func check_respawn():
	if enemy_count < max_enemies:
		var respawn_delay = randf_range(respawn_min_time, respawn_max_time)
		spawn_enemy("fighter1")
		#get_tree().create_timer(respawn_delay).timeout.connect(spawn_enemy("fighter1"))
		
func spawn_enemy(type_or_config):
	var safe_distance = 800  # Minimum distance from player
	var player_position = get_node("/root/Asteroided/Player").global_position
	var spawn_position = Vector2.ZERO
	while true:
		spawn_position = Vector2(randf_range(0, 10000), randf_range(0, 10000))
		
		# Ensure enemy spawns outside player's view range
		if player_position.distance_to(spawn_position) > safe_distance:
			break  # Valid spawn location found

	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.global_position = spawn_position

	# Setup enemy depending on whether it's a predefined type or an existing config
	if type_or_config is String and type_or_config in enemy_data:
		enemy.setup(enemy_data[type_or_config])  # If it's a type, use predefined config
	else:
		enemy.setup(type_or_config)  # If it's already a full config, just apply it
	call_deferred("add_child", enemy)  # Defer addition to avoid performance issues
	
func spawn_random_enemy():
	var safe_distance = 1200  # Minimum distance from player
	var player_position = 0
	if(get_node("/root/Asteroided/Player")):
		player_position = get_node("/root/Asteroided/Player").global_position
	else:
		print("No player found")
		return(0)
	var spawn_position = Vector2.ZERO

	while true:
		spawn_position = Vector2(randf_range(0, 5000), randf_range(0, 5000))
		
		# Ensure enemy spawns outside player's view range
		if player_position.distance_to(spawn_position) > safe_distance:
			break  # Valid spawn location found
	
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.global_position = spawn_position
	var rand = randf_range(0,100)
	if rand < 90:
		enemy.setup(enemy_data["fighter1"])
	else:
		enemy.setup(enemy_data["interceptor1"])
	call_deferred("add_child", enemy)
	
	
func _ready():
	for i in range(max_enemies):  # Spawn 10 enemies
		spawn_random_enemy()
