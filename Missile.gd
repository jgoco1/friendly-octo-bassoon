extends Area2D
@export var explosion_scene: PackedScene  # Assign an explosion effect
@onready var missile_lock_player = AudioStreamPlayer.new()
@onready var sprite = $AnimatedSprite2D

@export var speed: float = 200  # Missile speed
@export var turn_speed: float = 3  # How fast it adjusts course
@export var target_group: String = "player_units"  # Determines what it locks onto
@export var damage: int = 50
@export var tracking: bool = true  # If true, missile homes in on a target
var target = null

var max_range = 1000
var traveled_distance = 0
var explosion_radius: float

func assign_values(missile_id):
	var missile_data = GameManager.missile_types.get(missile_id, GameManager.missile_types["AIM-120"])  # Use default if not found
	turn_speed = 2 * missile_data["turn_speed"]
	speed = missile_data["speed"]
	max_range = missile_data["range"]
	damage = missile_data["damage"]
	explosion_radius = missile_data["explosion_radius"] / 2

	print("Missile assigned:", missile_id, "Stats:", missile_data)

func setup(start_pos, angle, velocity, dmg, m_range, m_explosion_radius):
	global_position = start_pos + Vector2.UP.rotated(angle) * 40  # Spawn slightly ahead
	rotation = angle
	speed += velocity
	var parent = get_parent()
	if parent and parent.is_in_group("player_units"):
		target_group = "enemies"
	elif parent and parent.is_in_group("enemies"):
		target_group = "player_units"

func _ready():
	assign_values("AIM-120")
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_entered", Callable(self, "_on_area_entered"))
	if target and not is_instance_valid(target):
		find_target()
	sprite.play("fly")  # Start flying animation

func _process(delta):
	find_target()
	var lead_target: Vector2
	if target:
		lead_target = await calculate_lead_target(target)
	move_forward(delta)
	# Determine rotation adjustment using cross product
	var forward_direction = Vector2.UP.rotated(rotation)
	var target_direction = (lead_target - global_position).normalized()
	var cross_product = forward_direction.cross(target_direction)
	# Gradually rotate toward the target direction
	rotation += turn_speed * cross_product * delta
	traveled_distance += speed * delta / 2 # Accumulate distance
	if traveled_distance >= max_range:
		explode()  # Detonate when max range is reached

func find_target():
	var targeting_angle = deg_to_rad(360) #deg_to_rad(turn_speed * 10)  # Adjust scaling factor for realism
	var possible_targets = get_tree().get_nodes_in_group(target_group)
	var best_target = null
	var best_distance = INF
	var forward_direction = Vector2.UP.rotated(rotation)  # Missile’s current forward direction

	for checkTarget in possible_targets:
		if !is_instance_valid(checkTarget):
			continue

		var to_target = (checkTarget.global_position - global_position).normalized()
		var angle_to_target = abs(forward_direction.angle_to(to_target))

		# Ensure target is within valid forward-facing radius
		if angle_to_target <= targeting_angle:
			var distance = global_position.distance_to(checkTarget.global_position)
			if distance < best_distance:
				best_distance = distance
				best_target = checkTarget

	target = best_target  # Assign the best target within the valid radius
	
func calculate_lead_target(target): #TODO - Rename the target variable here to avoid conflicts with overall target.
	if not is_instance_valid(target):  # Prevent accessing a freed object
		return global_position  # Default to current position if no valid target

	var previous_position = target.global_position
	await get_tree().create_timer(0.1).timeout  # Wait briefly

	if not is_instance_valid(target):  # Check again after waiting
		return global_position  # Prevent crash by returning current position
	
	var current_position = target.global_position
	var estimated_velocity = (current_position - previous_position) / 0.1  # Approximate velocity
	var time_to_target = global_position.distance_to(target.global_position) / speed

	var lead_position = target.global_position + (estimated_velocity * time_to_target)
	return lead_position

func move_forward(delta):
	var forward_direction = Vector2.UP.rotated(rotation)
	global_position += forward_direction * speed * delta / 2
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
	explosion.scale *= explosion_radius / 50  # Scale up explosion effect
	get_parent().add_child(explosion)

	for area in get_tree().get_nodes_in_group("player_units") + get_tree().get_nodes_in_group("enemies"):
		if !area.has_node("CollisionShape2D"):
			continue  # Skip if there's no collision shape
		
		var shape_node = area.get_node("CollisionShape2D")
		var shape = shape_node.shape
		var rect_extents = shape.extents if shape is RectangleShape2D else Vector2.ZERO  # Get rectangle size
		var area_center = area.global_position

		# Find closest point within the hitbox bounds
		var closest_x = clamp(global_position.x, area_center.x - rect_extents.x, area_center.x + rect_extents.x)
		var closest_y = clamp(global_position.y, area_center.y - rect_extents.y, area_center.y + rect_extents.y)
		var closest_point = Vector2(closest_x, closest_y)

		# Apply explosion damage based on distance
		var distance = global_position.distance_to(closest_point)
		if distance <= explosion_radius:
			var damage_factor = clamp(1.0 - (distance / explosion_radius), 0.1, 1.0)  # Scale damage
			area.take_damage(2 * damage * damage_factor)

	queue_free()
