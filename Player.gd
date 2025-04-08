extends CharacterBody2D

const EXPLOSION_SCENE = preload("res://Explosion.tscn")
@export var max_speed = 800 ##Max top speed
@export var rotation_speed = 0.2 ## How quickly it turns
@export var rtc_speed = .05 ##How quickly it returns to going straight
@export var max_bank_angle = 10 ##Max turn speed
@export var accel = 10 ##How Quickly it accellerates
@export var drag = 5 ##How quickly the ship decelerates

@onready var health_bar = get_node("/root/Asteroided/HealthUI/HealthBar")
@onready var bullet_scene = preload("res://bullet.tscn")

@export var max_health: int = 1000
var health: int = max_health

var speed = 0
var screenSize
var rotation_direction = 0
var gun = 5

var fire_rate = 20.0  # Adjust this to the desired shots per second
var shooting = false
var shoot_timer = 0.0
var bullet_velocity = 1600
var bullet_damage = 20
var bullet_range = 2000
var bullet_radius = 200

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
	add_to_group("player_units")
	screenSize = Vector2(5000, 5000)

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
	if health < max_health:
		var damage_level = 1.0 - float(health) / float(max_health)  # Determines severity
		if randf() < damage_level * delta * 3:  # Adjust spawn rate based on health
			spawn_damage_effect()
	health_bar.value = float(health) / float(max_health) * 100


func shoot():
	var bullet = bullet_scene.instantiate()
	# Offset position so the bullet spawns slightly ahead of the player
	var spawn_offset = Vector2(gun, -100).rotated(rotation) # Adjust the "-40" to change distance
	gun *= -1
	# Assign weapon stats dynamically
	bullet.setup(global_position+spawn_offset, rotation, (speed + bullet_velocity), bullet_damage, bullet_range, bullet_radius)  # Example values
	
	get_parent().add_child(bullet)
 # Add bullet to the scene
	
func spawn_damage_effect():
	var explosion = EXPLOSION_SCENE.instantiate()
	# Randomize position and scale
	explosion.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	explosion.scale *= randf_range(0.5, 1.5)  # Random scale between 0.5x and 1.5x
	get_parent().add_child(explosion)
	
func take_damage(amount):
	health -= amount
	# Flash effect on damage (optional)
	modulate = Color(1, 0.5, 0.5, 1)  # Brief red tint
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1, 1)  # Reset color
	if health <= 0:
		die()

func die():
	var explosion = EXPLOSION_SCENE.instantiate()  # Explosion effect
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	queue_free()  # Remove player from scene (can replace with respawn logic)
