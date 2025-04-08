extends Node2D

var enemy_data = {
	"fighter1": {
		"animation_frames": preload("res://fighter1.tres"),
		"speed": 250,
		"turn_radius": 3.5,
		"weapon_scene": preload("res://bullet.tscn"),
		"bullet_velocity": 1000,
		"bullet_damage": 15,
		"bullet_range": 1200,
		"bullet_explosion_radius": 80,
		"fire_rate": 1.0,
		"max_health": 100,
		"max_bank_angle": 15.0  # Fighter banks more
	},
	"interceptor1": {
		"animation_frames": preload("res://interceptor1_frames.tres"),
		"speed": 400,
		"turn_radius": 6.0,
		"weapon_scene": preload("res://Missile.tscn"),
		"bullet_velocity": 1000,
		"bullet_damage": 25,
		"bullet_range": 1500,
		"bullet_explosion_radius": 70,
		"fire_rate": 0.3,
		"max_health": 150,
		"max_bank_angle": 8.0  # Interceptor banks less
	}
}

var spawn_area = Rect2(300, 300, 1200, 800)  # Move closer to player view

func spawn_enemy(type, position):
	var enemy = preload("res://enemy.tscn").instantiate()
	enemy.global_position = position

	if type in enemy_data:
		enemy.setup(enemy_data[type])

	#enemy.player = get_node("/root/Asteroided/Player")  # Assign player reference

	call_deferred("add_child", enemy)  # Defer child addition

func _ready():
	for i in range(10):  # Spawn 10 enemies
		var random_pos = Vector2(randf_range(0, 5000), randf_range(00, 5000))
		spawn_enemy("fighter1", random_pos)
