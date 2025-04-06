extends Area2D

@onready var sprite = $AnimatedSprite2D  # Ensure this matches the node name in your Enemy scene

@export var animation_frames: SpriteFrames  # Assign animation frames in Inspector
@export var speed: float = 300
@export var turn_radius: float = 5.0
@export var weapon_scene: PackedScene
@export var targeting_range: float = 600
@export var enemy_type: String = "fighter"

var target = null

func _ready():
	if sprite:
		sprite.sprite_frames = animation_frames  # Set animation frames dynamically
		sprite.play("idle")  # Ensure the enemy starts in its idle animation
	else:
		print("Error: AnimatedSprite2D node not found!")

func _process(delta):
	if target:
		var direction = (target.global_position - global_position).normalized()
		rotation = rotation + (direction.angle() - rotation) * turn_radius * delta
		position += transform.x * speed * delta  # Move enemy
		
		# Play movement animation when moving
		sprite.play("move")

func find_target():
	var possible_targets = get_tree().get_nodes_in_group("player_units")
	for possible_target in possible_targets:
		if global_position.distance_to(possible_target.global_position) <= targeting_range:
			target = possible_target
			return

func shoot():
	if weapon_scene:
		var bullet = weapon_scene.instantiate()
		bullet.global_position = global_position
		bullet.rotation = rotation
		get_parent().add_child(bullet)
		sprite.play("attack")  # Play attack animation when shooting
