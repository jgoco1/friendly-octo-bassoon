extends Area2D

@export var speed: float = 200  # Missile speed
@export var turn_speed: float = 3  # How fast it adjusts course
@export var target_group: String = "player_units"  # Determines what it locks onto
@export var explosion_scene: PackedScene  # Assign an explosion effect
@export var damage: int = 50
@export var tracking: bool = true  # If true, missile homes in on a target
var target = null
@onready var sprite = $AnimatedSprite2D
var max_range = 1000
var traveled_distance = 0
var explosion_radius: float

func setup(start_pos, angle, velocity, dmg, m_range, explosion_radius):
	global_position = start_pos + Vector2.UP.rotated(angle) * 40  # Spawn slightly ahead
	rotation = angle
	speed = velocity
	damage = dmg
	max_range = m_range
	self.explosion_radius = explosion_radius

	# Determine the target group based on the firing unit
	var parent = get_parent()
	if parent and parent.is_in_group("player_units"):
		target_group = "enemies"
	elif parent and parent.is_in_group("enemies"):
		target_group = "player_units"

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_entered", Callable(self, "_on_area_entered"))
	if target and not is_instance_valid(target):
		find_target()
	sprite.play("fly")  # Start flying animation

func _process(delta):
	find_target()
	var movement_target: Vector2
	if target:
		movement_target = target.global_position
	move_forward(delta)
	# Determine rotation adjustment using cross product
	var forward_direction = Vector2.UP.rotated(rotation)
	var target_direction = (movement_target - global_position).normalized()
	var cross_product = forward_direction.cross(target_direction)
	# Gradually rotate toward the target direction
	rotation += turn_speed * cross_product * delta
	traveled_distance += speed * delta  # Accumulate distance
	
	if traveled_distance >= max_range:
		explode()  # Detonate when max range is reached

func find_target():
	var possible_targets = get_tree().get_nodes_in_group(target_group)
	
	if possible_targets.size() > 0:
		target = possible_targets.reduce(func(a, b):
			if !is_instance_valid(a):
				return b
			if !is_instance_valid(b):
				return a
			return a if a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position) else b
		)

func move_forward(delta):
	var forward_direction = Vector2.UP.rotated(rotation)
	global_position += forward_direction * speed * delta
	spawn_smoke()

func _on_body_entered(body):
	if body.is_in_group(target_group):
		explode()
		
func _on_area_entered(area):
	if area.is_in_group(target_group):  # Ensure enemy detection works
		explode()

func spawn_smoke():
	var smoke = preload("res://Explosion.tscn").instantiate()

	# Spawn slightly behind the missile
	smoke.global_position = global_position - Vector2.UP.rotated(rotation) * 20

	# Randomize size slightly for variation
	smoke.scale *= randf_range(0.2, 0.8)

	get_parent().add_child(smoke)

func explode():
	var explosion = preload("res://Explosion.tscn").instantiate()
	explosion.global_position = global_position
	# Scale up the explosion effect for missiles
	explosion.scale *= 4.0  # Adjust this value to control explosion size
	get_parent().add_child(explosion)
	
	for area in get_tree().get_nodes_in_group(target_group):
		if area.global_position.distance_to(global_position) <= explosion_radius:
			area.take_damage(damage)

	queue_free()  # Destroy missile
