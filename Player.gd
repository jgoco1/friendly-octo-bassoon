extends CharacterBody2D

var description:String = "A ship"

const EXPLOSION_SCENE = preload("res://Explosion.tscn")
const MISSILE_SCENE = preload("res://Missile.tscn")  # Single missile scene

var max_speed = 800 ##Max top speed
var rotation_speed = 0.2 ## How quickly it turns
@export var rtc_speed = .1 ##How quickly it returns to going straight
var max_bank_angle = 10 ##Max turn speed
var accel = 10 ##How Quickly it accelerates
var drag = 5 ##How quickly the ship decelerates

@onready var bullet_fire_player = AudioStreamPlayer.new()
#@onready var low_health_player = AudioStreamPlayer.new()

@onready var bullet_scene = preload("res://bullet.tscn")
@onready var missile_scene = preload("res://Missile.tscn")
var special_slots = []
@onready var camera = $Camera2D
var zoom_speed = 2000  # Adjust zoom speed
var min_zoom = 0.3  # Minimum zoom level (more zoomed in)
var max_zoom = 500.0  # Maximum zoom level (zoomed out)
@onready var health_bar = get_node("Camera2D/CanvasLayer/HealthBar")
@onready var score_label = get_node("Camera2D/CanvasLayer/Score")
@onready var missile_timer = get_node("Camera2D/CanvasLayer/MissileTimer")
@onready var flare_timer = get_node("Camera2D/CanvasLayer/ChaffTimer")
@onready var control = get_node("Camera2D/CanvasLayer/Control")
var max_health: int = 100
var health: int = max_health

var speed = 0
var screenSize
var rotation_direction = 0
var gun = 5 #distance between 2 guns on ship (enter 0 if you want shots to come from center)

var fire_rate = 40.0  # Adjust this to the desired shots per second
var shooting = false
var shoot_timer = 0.0
var special_cooldown = 3
var special_timer = 0.0
var chaff_cooldown = 3
var chaff_timer = 0.0
var special_2_count = 6
var bullet_velocity = 1600
var bullet_damage = 20
var bullet_range = 2000
var bullet_radius = 200
var bullet_spread = .05
var spread = .05
##max_speed, rotation_speed, max_bank_angle, accel, drag
##bullet_scene, missile_scene
##max_health, fire_rate, special_cooldown, bullet_velocity, bullet_damage, bullet_range, bullet_radius
var sprite_scale = 2 # default scaling

func get_input():
	# Handle rotation controls
	if abs(rotation_direction + (Input.get_axis("left", "right") * rotation_speed)) < max_bank_angle:
		rotation_direction += Input.get_axis("left", "right") * rotation_speed

	if abs(rotation_direction) > 0 and !Input.get_axis("left", "right"):
		rotation_direction = lerp(rotation_direction, 0.0, rtc_speed)

	# Handle forward movement
	speed += Input.get_axis("down", "up") * accel
	if (!Input.get_axis("down", "up")):
		speed -= drag
	speed = clamp(speed, 0, max_speed)

	# Handle strafing
	var strafe_speed = rotation_speed * 2000  # Defines lateral movement speed
	var strafe_direction = Input.get_axis("Strafe_Left", "Strafe_Right")

	var lateral_movement = transform.x * strafe_speed * strafe_direction
	velocity = transform.y * speed * -1 + lateral_movement  # Apply independent strafe

func _ready():
	if GameManager.selected_missiles.size() > 0:
		print("Assigning missiles")
		special_slots = GameManager.selected_missiles  # Assign player's missile loadout
		print(special_slots)
	else:
		print("Couldn't find missiles")
		# Fallback to default missiles from player type
		var ship_type = GameManager.selected_ship_type
		special_slots = GameManager.player_types[ship_type].get("special_scenes", [])

	assign_values(GameManager.selected_ship_type)  # Use the selected ship
	add_to_group("player_units")
	var display_size = get_viewport_rect().size  # Get current screen resolution
	var base_zoom = display_size / Vector2(1920, 1080)  # Normalize zoom based on a 1080p reference
	camera.zoom = .4*base_zoom
	screenSize = Vector2(23720, 17160)
	if health_bar:
		health_bar.value = float(health) / float(max_health) * 100
		health_bar.add_theme_color_override("font_color", Color(0, 0, 0))  # Ensures text stays black
		health_bar.modulate = Color(0,1,0,2)
	add_child(bullet_fire_player)
	bullet_fire_player.stream = preload("res://sound/laserShoot.wav")
	bullet_fire_player.volume_db = 0

func assign_values(type: String):
	if type in GameManager.player_types:
		var config = GameManager.player_types[type]
		
		# Assign stats
		max_speed = config["max_speed"]
		rotation_speed = config["rotation_speed"]
		max_bank_angle = config["max_bank_angle"]
		accel = config["accel"]
		drag = config["drag"]
		max_health = config["max_health"]
		fire_rate = config["fire_rate"]
		special_cooldown = config["special_cooldown"]
		bullet_velocity = config["bullet_velocity"]
		bullet_damage = config["bullet_damage"]
		bullet_range = config["bullet_range"]
		bullet_radius = config["bullet_radius"]
		spread = config["bullet_spread"]

		# Assign visuals & weapons
		$AnimatedSprite2D.frames = config["animation_frames"]
		bullet_scene = config["bullet_scene"]
		
		# Set missile loadout (prioritizing selected missiles)
		if GameManager.selected_missiles.size() > 0:
			special_slots = GameManager.selected_missiles
		else:
			special_slots = config.get("special_scenes", [])

		sprite_scale = config.get("sprite_scale", 1.0)
		var collision_scale = config.get("collision_scale", 1.0)

		$AnimatedSprite2D.scale = Vector2(sprite_scale, sprite_scale)
		$CollisionShape2D.scale = Vector2(collision_scale, collision_scale)

		# Set health properly after reassignment
		health = max_health

func _physics_process(delta):
	get_input()
	rotation += rotation_direction * delta
	move_and_slide()
	position += velocity * delta  # Now includes strafing effect

	position.x = clamp(position.x, 0, screenSize.x)
	position.y = clamp(position.y, 0, screenSize.y)
	
	$AnimatedSprite2D.flip_h = false
	if(velocity) :
		if(rotation_direction < 0):
			$AnimatedSprite2D.flip_h = true
		if(abs(rotation_direction) > max_bank_angle / 1.2) : #IF greater than half of max bank angle
			$AnimatedSprite2D.play("Hard_Bank")
		elif(abs(rotation_direction) > max_bank_angle / 4):
			$AnimatedSprite2D.play("Med_Bank")
		else:
			$AnimatedSprite2D.play("Forward")
	else:
		$AnimatedSprite2D.play("default")
	score_label.text = "Score: " + str(GameManager.lifetime_score)

func _process(delta):
	 # Detect mouse wheel movement for zooming
	var scroll_up = Input.is_action_just_pressed("Zoom_Out")  # Scroll Up
	var scroll_down = Input.is_action_just_pressed("Zoom_In")  # Scroll Down
	if scroll_up:
		camera.zoom = (camera.zoom - Vector2(0.1, 0.1)).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
	if scroll_down:
		camera.zoom = (camera.zoom + Vector2(0.1, 0.1)).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

	if Input.is_action_pressed("shoot"):
		shooting = true
		#bullet_fire_player.playing = true
	else:
		shooting = false
		bullet_fire_player.playing = false
	if shooting:
		shoot_timer -= delta
		if shoot_timer <= 0:
			shoot()
			shoot_timer = 1.0 / fire_rate
	if (special_timer <= 0):
		if Input.is_action_pressed("special"):
			special_timer += special_cooldown
			use_special()
	else:
		special_timer -= delta
		
	if (chaff_timer <= 0):
		if(Input.is_action_pressed("special_2")):
			chaff_timer += chaff_cooldown
			deploy_countermeasures(special_2_count)
	else:
		chaff_timer -= delta
	if missile_timer:
		missile_timer.value = float(special_timer) / float(special_cooldown) * 100
	if flare_timer:
		flare_timer.value = float(chaff_timer) / float(chaff_cooldown) * 100
		
	if health < max_health:
		var damage_level = 1.0 - float(health) / float(max_health)  # Determines severity
		var spawn_chance = damage_level * delta * 12  # Increased multiplier for lower health
		if randf() < spawn_chance:
			spawn_damage_effect()

func shoot():
	var bullet = bullet_scene.instantiate()
	# Offset position so the bullet spawns slightly ahead of the player
	var spawn_offset = Vector2(gun, -60).rotated(rotation) # Adjust the "-40" to change distance
	gun *= -1
	# Assign weapon stats dynamically
	bullet.setup(global_position+(spawn_offset*sprite_scale),(rotation + randf_range(-spread,spread) ), ((speed*1.5) + bullet_velocity), bullet_damage, bullet_range, bullet_radius)  # Example values
	get_parent().add_child(bullet)
	 # Add bullet to the scene
	 # Play bullet sound only if it's not already playing
	if not bullet_fire_player.playing:
		bullet_fire_player.play()

func use_special():
	var missile_delay = 0.2  # Delay between missile launches
	var total_specials = special_slots.size()

	for i in range(total_specials):  # Fire based on array size
		await get_tree().create_timer(missile_delay * i).timeout
		launch_special(special_slots[i])
		
func launch_special(missile_id):
	var special = MISSILE_SCENE.instantiate()  # Use the preloaded missile scene
	# Offset missiles slightly for variation
	var offset = Vector2(randf_range(-20, 20), -100).rotated(rotation)
	#func setup(start_pos, angle, velocity, dmg, m_range, m_explosion_radius):
	special.setup(global_position + offset, rotation, speed + 500, 10, 3000, 200)  # Temporary values before assignment
	special.assign_values(missile_id)  # Missile handles validation internally
	special.target_group = "enemies"
	get_parent().add_child(special)
	
func deploy_countermeasures(amount: int):
	for i in range(amount):
		var cm = preload("res://Countermeasure.tscn").instantiate()
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		cm.global_position = global_position + offset
		cm.effective_time = 3.5
		cm.initial_size = 1.8
		cm.fade_rate = 1.0
		cm.add_to_group("player_units")  # or "enemies"
		get_parent().add_child(cm)
		
func spawn_damage_effect():
	var explosion = EXPLOSION_SCENE.instantiate()
	# Randomize position and scale
	explosion.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	explosion.scale *= randf_range(0.5, 1.5)  # Random scale between 0.5x and 1.5x
	explosion.modulate = Color(0.5, 0.5, 0.5, randf_range(.3,1))
	get_parent().add_child(explosion)
	
func take_damage(amount):
	health -= amount
	health = max(health, 0)  # Ensure health doesn't drop below zero
	
	if health_bar:
		health_bar.value = float(health) / float(max_health) * 100
		
		# Calculate color transition from green to red
		var health_ratio = float(health) / max_health
		var new_color = Color(1.0, health_ratio, health_ratio * 0.5, 2)  # More red as health decreases
		health_bar.modulate = new_color
	
	# Flash effect on damage (optional)
	modulate = Color(1, 0.5, 0.5, 1)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1, 1)
	#
	#if health <= max_health and not low_health_player.playing:
		#low_health_player.play()
	
	if health <= 0:
		die()

func die():
	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.global_position = global_position
	explosion.scale *= randf_range(3,5)
	get_parent().add_child(explosion)

	await get_tree().create_timer(.25).timeout  # Delay before returning to menu

	queue_free()  # Remove player from scene
	GameManager.handle_death()
