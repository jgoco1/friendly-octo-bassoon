extends CharacterBody2D

var description:String = "A ship"
var ship_type = "Pi_Fighter"

const EXPLOSION_SCENE = preload("res://Explosion.tscn")
@export var max_speed = 800 ##Max top speed
@export var rotation_speed = 0.2 ## How quickly it turns
@export var rtc_speed = .05 ##How quickly it returns to going straight
@export var max_bank_angle = 10 ##Max turn speed
@export var accel = 10 ##How Quickly it accelerates
@export var drag = 5 ##How quickly the ship decelerates

@onready var bullet_scene = preload("res://bullet.tscn")
@onready var missile_scene = preload("res://Missile.tscn")
@onready var health_bar = get_node("Camera2D/CanvasLayer/HealthBar")
@onready var score_label = get_node("Camera2D/CanvasLayer/Score")
@onready var missile_timer = get_node("Camera2D/CanvasLayer/MissileTimer")
@export var max_health: int = 100
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
var bullet_velocity = 1600
var bullet_damage = 20
var bullet_range = 2000
var bullet_radius = 200
##max_speed, rotation_speed, max_bank_angle, accel, drag
##bullet_scene, missile_scene
##max_health, fire_rate, special_cooldown, bullet_velocity, bullet_damage, bullet_range, bullet_radius

var player_types = {
	"default" : {
		"description": "Interceptor - Well rounded choice",
		"animation_frames": preload("res://interceptor1.tres"),
		"bullet_scene": preload("res://bullet.tscn"),
		"missile_scene": preload("res://Missile.tscn"),
		"max_speed": 1500,
		"rotation_speed": 0.1,
		"max_bank_angle": 10,
		"accel": 8,
		"drag": 4,
		"max_health": 400,
		"fire_rate": 10,
		"special_cooldown": 2,
		"bullet_velocity": 1600,
		"bullet_damage": 20,
		"bullet_range": 2000,
		"bullet_radius": 200
	},
	"Pi_Fighter" : {
		"description": "A highly maneuverable dog-fighter. 
						Slower top speed but fast acceleration and banking. 
						Reducing power budget for shields allows greater firepower for main guns, 
						but the lack of a targetting droid means missiles take longet to recharge.",
		"animation_frames": preload("res://fighter1.tres"),
		"bullet_scene": preload("res://bullet.tscn"),
		"missile_scene": preload("res://Missile.tscn"),
		"max_speed": 800,
		"rotation_speed": 0.3,
		"max_bank_angle": 10,
		"accel": 20,
		"drag": 8,
		"max_health": 100,
		"fire_rate": 60,
		"special_cooldown": 10,
		"bullet_velocity": 2000,
		"bullet_damage": 20,
		"bullet_range": 1500,
		"bullet_radius": 150
	}
}

func get_input():
	if abs(rotation_direction + (Input.get_axis("left", "right") * rotation_speed)) < max_bank_angle: ##Limit max turn
		rotation_direction = rotation_direction + (Input.get_axis("left", "right") * rotation_speed)

	if abs(rotation_direction) > 0 and !Input.get_axis("left", "right"):
		rotation_direction = lerp(rotation_direction, 0.0, rtc_speed)
	
	speed += Input.get_axis("down", "up") * accel
	if(!Input.get_axis("down", "up")):
		speed -= drag
	speed = clamp(speed, 0, max_speed)
	
	velocity = transform.y * speed * -1 ##Track forward speed

func _ready():
	assign_values(ship_type)
	add_to_group("player_units")
	screenSize = Vector2(10000, 10000)
	if health_bar:
		health_bar.value = float(health) / float(max_health) * 100
		health_bar.add_theme_color_override("font_color", Color(0, 0, 0))  # Ensures text stays black
		health_bar.modulate = Color(0,1,0,2)
		
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

		# Assign visuals & weapons
		$AnimatedSprite2D.frames = config["animation_frames"]
		bullet_scene = config["bullet_scene"]
		missile_scene = config["missile_scene"]

		# Set health properly after reassignment
		health = max_health

func _physics_process(delta):
	get_input()
	rotation += rotation_direction * delta
	move_and_slide()
	position += velocity * delta
	position.x = clamp(position.x, 0, screenSize.x)
	position.y = clamp(position.y, 0, screenSize.y)
	$AnimatedSprite2D.flip_v = false
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
	if Input.is_action_pressed("shoot"):
		shooting = true
	else:
		shooting = false
	if shooting:
		shoot_timer -= delta
		if shoot_timer <= 0:
			shoot()
			shoot_timer = 1.0 / fire_rate
	if (special_timer <= 0):
		if Input.is_action_pressed("special"):
			special_timer += special_cooldown
			special()
	else:
		special_timer -= delta
	if missile_timer:
		missile_timer.value = float(special_timer) / float(special_cooldown) * 100
		
	if health < max_health:
		var damage_level = 1.0 - float(health) / float(max_health)  # Determines severity
		var spawn_chance = damage_level * delta * 6  # Increased multiplier for lower health
		if randf() < spawn_chance:
			spawn_damage_effect()

func shoot():
	var bullet = bullet_scene.instantiate()
	# Offset position so the bullet spawns slightly ahead of the player
	var spawn_offset = Vector2(gun, -100).rotated(rotation) # Adjust the "-40" to change distance
	gun *= -1
	# Assign weapon stats dynamically
	bullet.setup(global_position+spawn_offset, rotation, (speed + bullet_velocity), bullet_damage, bullet_range, bullet_radius)  # Example values
	
	get_parent().add_child(bullet)
 # Add bullet to the scene

func special():
	var special = missile_scene.instantiate()
	var spawn_offset = Vector2(0, -100).rotated(rotation)
	special.setup(global_position+spawn_offset, rotation, (speed+bullet_velocity), bullet_damage*2, bullet_range*5, bullet_radius)
	special.target_group = "enemies"
	special.turn_speed = 5
	get_parent().add_child(special)
	
func spawn_damage_effect():
	var explosion = EXPLOSION_SCENE.instantiate()
	# Randomize position and scale
	explosion.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	explosion.scale *= randf_range(0.5, 1.5)  # Random scale between 0.5x and 1.5x
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
