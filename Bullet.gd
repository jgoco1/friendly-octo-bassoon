extends Area2D

@export var speed: float = 1200
var direction: Vector2
var damage: int
var explosion_radius: float
var traveled_distance: float = 0.0
var max_range: float


func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	add_to_group("player_bullets")
	connect("area_entered", Callable(self, "_on_area_entered"))


func _process(delta):
	var movement = direction * speed * delta
	global_position += movement
	traveled_distance += movement.length()

	# Explode when reaching max range
	if traveled_distance >= max_range:
		explode()

func setup(start_pos, angle, velocity, dmg, range, explosion_radius):
	global_position = start_pos
	rotation = angle
	direction = Vector2.UP.rotated(rotation)
	speed = velocity
	damage = dmg
	max_range = range
	self.explosion_radius = explosion_radius


func _on_body_entered(body):
	if body.is_in_group("enemies") or body.is_in_group("player_units"):
		explode()
		
func _on_area_entered(area):
	if area.is_in_group("enemies"):  # Ensure enemy detection works
		explode()


func explode():
	var explosion = preload("res://explosion.tscn").instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)

	for area in get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("player_units"):
		if area.global_position.distance_to(global_position) <= explosion_radius:
			area.take_damage(damage)


	queue_free()  # Destroy bullet after explosion
