extends CharacterBody2D

var description:String = "A ship"

const EXPLOSION_SCENE = preload("res://Explosion.tscn")
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
@onready var camera = $Camera2D
var zoom_speed = 2000  # Adjust zoom speed
var min_zoom = 0.3  # Minimum zoom level (more zoomed in)
var max_zoom = 500.0  # Maximum zoom level (zoomed out)
@onready var health_bar = get_node("Camera2D/CanvasLayer/HealthBar")
@onready var score_label = get_node("Camera2D/CanvasLayer/Score")
@onready var missile_timer = get_node("Camera2D/CanvasLayer/MissileTimer")
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
var num_spcl = 1
var bullet_velocity = 1600
var bullet_damage = 20
var bullet_range = 2000
var bullet_radius = 200
var bullet_spread = .05
var spread = .05
##max_speed, rotation_speed, max_bank_angle, accel, drag
##bullet_scene, missile_scene
##max_health, fire_rate, special_cooldown, bullet_velocity, bullet_damage, bullet_range, bullet_radius

var player_types = {
	"Bomber" : {
		"description": "Interceptor - Well rounded choice",
		"animation_frames": preload("res://interceptor1.tres"),
		"bullet_scene": preload("res://bullet.tscn"),
		"missile_scene": preload("res://Missile.tscn"),
		"collision_scale" : 3,
		"sprite_scale": 3,
		"max_speed": 1300,
		"rotation_speed": 0.1,
		"max_bank_angle": 13,
		"accel": 8,
		"drag": 4,
		"max_health": 300,
		"fire_rate": 2,
		"special_cooldown": 2,
		"bullet_velocity": 1800,
		"bullet_damage": 20,
		"bullet_range": 2500,
		"bullet_spread": .02,
		"num_spcl" : 2,
		"bullet_radius": 200
	},
	"Cross_Wing" : {
		"description": "A starfighter",
		"animation_frames": preload("res://xwingv1.tres"),
		"bullet_scene": preload("res://bullet.tscn"),
		"missile_scene": preload("res://Missile.tscn"),
		"collision_scale" : 3,
		"sprite_scale": 3,
		"max_speed": 900,
		"rotation_speed": 0.25,
		"max_bank_angle": 10,
		"accel": 15,
		"drag": 6,
		"max_health": 150,
		"fire_rate": 20,
		"special_cooldown": 4,
		"bullet_velocity": 2400,
		"bullet_damage": 15,
		"bullet_range": 2500,
		"bullet_spread": .1,
		"num_spcl" : 1,
		"bullet_radius": 100
	},
	"Pi_Fighter" : {
		"description": "A highly maneuverable dog-fighter. 
						Slower top speed but fast acceleration and banking. 
						Reducing power budget for shields allows greater firepower for main guns, 
						but the lack of a targetting droid means missiles take longer to recharge.",
		"animation_frames": preload("res://fighter1.tres"),
		"bullet_scene": preload("res://bullet.tscn"),
		"missile_scene": preload("res://Missile.tscn"),
		"collision_scale" : 3,
		"sprite_scale": 3,
		"max_speed": 700,
		"rotation_speed": 0.3,
		"max_bank_angle": 10,
		"accel": 20,
		"drag": 8,
		"max_health": 100,
		"fire_rate": 150,
		"special_cooldown": 10,
		"bullet_velocity": 3000,
		"bullet_damage": 10,
		"bullet_range": 2000,
		"bullet_spread": .08,
		"num_spcl" : 1,
		"bullet_radius": 150
	}
}

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
	assign_values(GameManager.selected_ship_type)  # Use the selected ship
	add_to_group("player_units")
	var display_size = get_viewport_rect().size  # Get current screen resolution
	var base_zoom = display_size / Vector2(1920, 1080)  # Normalize zoom based on a 1080p reference
	camera.zoom = .4*base_zoom
	screenSize = Vector2(20000, 20000)
	if health_bar:
		health_bar.value = float(health) / float(max_health) * 100
		health_bar.add_theme_color_override("font_color", Color(0, 0, 0))  # Ensures text stays black
		health_bar.modulate = Color(0,1,0,2)
	add_child(bullet_fire_player)
	bullet_fire_player.stream = preload("res://sound/laserShoot.wav")
	bullet_fire_player.volume_db = -1
	#
	#add_child(low_health_player)
	#low_health_player.stream = preload("res://sound/alert-102266.mp3")
	#low_health_player.volume_db = -15
	

func assign_values(type: String):
	if type in player_types:
		var config = player_types[type]
		
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
		num_spcl = config["num_spcl"]

		# Assign visuals & weapons
		$AnimatedSprite2D.frames = config["animation_frames"]
		bullet_scene = config["bullet_scene"]
		missile_scene = config["missile_scene"]

		var sprite_scale = config.get("sprite_scale", 1.0)
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
	score_label.text = "Score: " + str(GameManager.score)

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
	if missile_timer:
		missile_timer.value = float(special_timer) / float(special_cooldown) * 100
		
	if health < max_health:
		var damage_level = 1.0 - float(health) / float(max_health)  # Determines severity
		var spawn_chance = damage_level * delta * 12  # Increased multiplier for lower health
		if randf() < spawn_chance:
			spawn_damage_effect()

func shoot():
	var bullet = bullet_scene.instantiate()
	# Offset position so the bullet spawns slightly ahead of the player
	var spawn_offset = Vector2(gun, -120).rotated(rotation) # Adjust the "-40" to change distance
	gun *= -1
	# Assign weapon stats dynamically
	bullet.setup(global_position+spawn_offset,(rotation + randf_range(-spread,spread) ), ((speed*1.5) + bullet_velocity), bullet_damage, bullet_range, bullet_radius)  # Example values
	get_parent().add_child(bullet)
	 # Add bullet to the scene
	 # Play bullet sound only if it's not already playing
	#if not bullet_fire_player.playing:
		#bullet_fire_player.play()


func use_special():
	#var num_spcl = player_types[GameManager.selected_ship_type].get("num_spcl", 1)
	var missile_delay = 0.2  # Delay between missile launches

	for i in range(num_spcl):
		await get_tree().create_timer(missile_delay * i).timeout  # Delay per missile
		launch_special(i, num_spcl)
		
func launch_special(index, total):
	var special = missile_scene.instantiate()

	# Offset missiles slightly for variation
	var offset = Vector2(index * 10 - (total * 5), -100).rotated(rotation)

	special.setup(global_position + offset, rotation, (speed + (bullet_velocity / 1.5)), bullet_damage * 3, bullet_range * 5, bullet_radius)
	special.target_group = "enemies"
	special.turn_speed = 5

	get_parent().add_child(special)
	
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
	GameManager.return_to_menu()
