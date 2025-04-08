extends Area2D

var smoke_timer = 0.0
var smoke_rate = 1.0  # Adjust rate for smoke emission

@onready var sprite = $AnimatedSprite2D  # Ensure this matches the node name in your Enemy scene
@export var explosion_scene: PackedScene  # Assign your Explosion.tscn in the Inspector
@export var animation_frames: SpriteFrames  # Assign animation frames in Inspector
@export var speed: float = 300
@export var turn_radius: float = 5.0
@export var weapon_scene: PackedScene
@export var targeting_range: float = 1000
@export var enemy_type: String = "fighter"
@export var max_health: int = 100  # Set in Inspector for different enemy types
@export var rotation_speed: float = 4  # Speed at which enemies adjust their heading
var health: int = max_health
var play_area = Rect2(100, 100, 5000, 5000)  # Define playable space
var fire_rate = 0.5  # Reduce cooldown (shoots faster)
var shoot_timer = 0.0

var bullet_velocity: float
var bullet_damage: int
var bullet_range: float
var bullet_explosion_radius: float
var target = null
var enemy_config
var strafe_offset = 300  # Distance for strafing behavior
var wander_target: Vector2 = Vector2.ZERO  # Ensure correct type

var rotation_direction = 0

func move_toward_point(target: Vector2, speed: float, delta: float):
	var direction = (target - global_position).normalized()
	global_position += direction * speed * delta
	
	var forward_direction = Vector2.UP.rotated(rotation)  # Current facing direction
	var target_direction = (target - global_position).normalized()
	var cross_product = forward_direction.cross(target_direction) #If product is greater than 0, target is to the left

func _process(delta):
	find_target()
	var movement_target: Vector2
	
	if target:
		movement_target = target.global_position
	else:
		movement_target = wander_target
		if global_position.distance_to(wander_target) < 20:
			set_random_target()

	move_forward(delta)

	# Determine rotation adjustment using cross product
	var forward_direction = Vector2.UP.rotated(rotation)
	var target_direction = (movement_target - global_position).normalized()
	var cross_product = forward_direction.cross(target_direction)

	# Gradually rotate toward the target direction
	rotation += rotation_speed * cross_product * delta


	# Faster shooting while targeting player
	if target:
		shoot_timer -= delta
		if shoot_timer <= 0:
			shoot()
			shoot_timer = fire_rate  # Reset cooldown for next shot
	if health < max_health:
		var health_ratio = float(health) / max_health
		smoke_timer -= delta

		var adjusted_smoke_rate = clamp(1.5 - health_ratio, 0.2, 1.5)  # Faster emission at lower health
		if smoke_timer <= 0:
			emit_smoke()
			smoke_timer = adjusted_smoke_rate  # Reduce interval as health decreases

func set_random_target():
	var random_offset = Vector2(randf_range(-600, 600), randf_range(-600, 600))  # Natural variation
	var new_position = global_position + random_offset

	# Ensure new position stays within bounds
	new_position.x = clamp(new_position.x, play_area.position.x, play_area.end.x)
	new_position.y = clamp(new_position.y, play_area.position.y, play_area.end.y)

	wander_target = new_position
	
func setup(config):
	enemy_config = config
	animation_frames = enemy_config["animation_frames"]
	speed = enemy_config["speed"]
	turn_radius = enemy_config["turn_radius"]
	weapon_scene = enemy_config["weapon_scene"]

	# Store bullet-related values
	bullet_velocity = enemy_config["bullet_velocity"]
	bullet_damage = enemy_config["bullet_damage"]
	bullet_range = enemy_config["bullet_range"]
	bullet_explosion_radius = enemy_config["bullet_explosion_radius"]

	# Store health and fire rate values
	max_health = enemy_config["max_health"]
	health = max_health
	fire_rate = enemy_config.get("fire_rate", 0.5)  # Default to 0.5 if not set

	

func _ready():
	add_to_group("enemies")
	set_random_target()
	modulate = Color(1,1,1,1)
	if sprite:
		sprite.sprite_frames = animation_frames  # Set animation frames dynamically
		sprite.play("default")  # Ensure the enemy starts in its idle animation
	else:
		print("Error: AnimatedSprite2D node not found!")

func find_target():
	var possible_targets = get_tree().get_nodes_in_group("player_units")
	if target and global_position.distance_to(target.global_position) > targeting_range * 1.5:  # Lose target if too far
		target = null
	
	
	for possible_target in possible_targets:
		if global_position.distance_to(possible_target.global_position) <= targeting_range:
			target = possible_target
			return
func move_forward(delta):
	var forward_direction = Vector2.UP.rotated(rotation)
	global_position += forward_direction * speed * delta
	
func shoot():
	if weapon_scene:
		var bullet = weapon_scene.instantiate()
		
		# Spawn the bullet slightly ahead of the enemy
		var spawn_offset = Vector2(0, -80).rotated(rotation)  # Adjusted for correct forward placement
		bullet.global_position = global_position + spawn_offset

		# Calculate the enemy's current velocity
		var enemy_velocity = Vector2.UP.rotated(rotation) * speed

		# Ensure bullets move forward with inherited velocity
		var bullet_velocity_vector = Vector2.UP.rotated(rotation) * bullet_velocity + enemy_velocity
		
		bullet.setup(global_position + spawn_offset, rotation, bullet_velocity_vector.length(), bullet_damage, bullet_range, bullet_explosion_radius)
		
		get_parent().add_child(bullet)
		
func take_damage(amount):
	health -= amount
	
	if health <= 0:
		die()
		
func emit_smoke():
	var health_ratio = float(health) / max_health  # Get remaining health percentage
	var smoke_intensity = clamp(1.5 - health_ratio, 0.5, 1.5)  # More smoke as health decreases
	
	var smoke = explosion_scene.instantiate()  # Reusing explosion effect
	smoke.global_position = global_position
	smoke.modulate = Color(0.5, 0.5, 0.5, 0.8 * smoke_intensity)  # Adjust transparency with damage level
	
	get_parent().add_child(smoke)
	
func die():
	var explosion = explosion_scene.instantiate()  # Play explosion effect
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	
	queue_free()  # Remove enemy from the scene
