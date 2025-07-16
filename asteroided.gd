extends Node2D
var selected_ship_type = "default"  # Default starting selection

var screenSize = Vector2(23720, 17160)

var enemy_scene = preload("res://enemy.tscn")

var enemy_count = 0
var max_enemies = 30  # Adjust based on desired difficulty
#var respawn_min_time = 2.0  # Minimum respawn delay
#var respawn_max_time = 6.0  # Maximum respawn delay
	
func spawn_enemy(type_or_config):
	var safe_distance = 800  # Minimum distance from player
	var player_position = get_node("/root/Asteroided/Player").global_position
	var spawn_position = Vector2.ZERO

	while true:
		spawn_position = Vector2(randf_range(0, screenSize.x), randf_range(0, screenSize.y))
		if player_position.distance_to(spawn_position) > safe_distance:
			break  # Valid spawn location found

	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.global_position = spawn_position

	if type_or_config is String and type_or_config in GameManager.enemy_data:
		enemy.setup(GameManager.enemy_data[type_or_config])  # Pull enemy config from GameManager
	else:
		enemy.setup(type_or_config)  # Apply external config if provided

	call_deferred("add_child", enemy)
	
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
		spawn_position = Vector2(randf_range(0, screenSize.x), randf_range(0, screenSize.y))
		
		# Ensure enemy spawns outside player's view range
		if player_position.distance_to(spawn_position) > safe_distance:
			break  # Valid spawn location found
	
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.global_position = spawn_position
	var rand = randf_range(0,100)
	#print(rand)
	if rand < 70:
		enemy.setup(GameManager.enemy_data["fighter1"])
	elif rand < 90:
		enemy.setup(GameManager.enemy_data["fighter2"])
	else:
		enemy.setup(GameManager.enemy_data["interceptor1"])
	call_deferred("add_child", enemy)
	
func _ready():
	for i in range(max_enemies):  # Spawn 10 enemies
		spawn_random_enemy()
