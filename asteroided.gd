extends Node2D
var enemy_data = {
	"fighter1": {
		"animation_frames": preload("res://fighter1_frames.tres"),
		"speed": 250,
		"turn_radius": 3.5,
		"weapon_scene": preload("res://bullet.tscn")
	},
	"interceptor1": {
		"animation_frames": preload("res://interceptor1_frames.tres"),
		"speed": 400,
		"turn_radius": 6.0,
		"weapon_scene": preload("res://missile.tscn")
	}
}

func spawn_enemy(type, position):
	var enemy = preload("res://Enemy.tscn").instantiate()
	enemy.global_position = position

	if type in enemy_data:
		var config = enemy_data[type]
		enemy.animation_frames = config["animation_frames"]
		enemy.speed = config["speed"]
		enemy.turn_radius = config["turn_radius"]
		enemy.weapon_scene = config["weapon_scene"]

	get_parent().add_child(enemy)
