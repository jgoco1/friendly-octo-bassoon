extends Area2D

@export var velocity = 800
@export var damage = 10
@export var range = 1000
@export var explosion_radius = 50

@export var explosion_scene: PackedScene  # Assign your Explosion.tscn in the inspector

var start_position

func _ready():
	start_position = global_position

func _process(delta):
	position += transform.y * velocity * -delta

	if global_position.distance_to(start_position) >= range:
		explode()

func explode():
	var explosion = explosion_scene.instantiate()
	get_parent().add_child(explosion)  # Add first before setting position
	explosion.global_position = global_position  # Move it precisely to the bullet's last location
	
	# Handle damage to nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.global_position.distance_to(global_position) <= explosion_radius:
			enemy.take_damage(damage)

	queue_free()  # Remove the bullet
