extends Area2D

@export var speed: float = 400  # Missile speed
@export var turn_speed: float = 2.0  # How fast it adjusts course
@export var target_group: String = "enemies"  # Determines what it locks onto
@export var explosion_scene: PackedScene  # Assign an explosion effect
@export var damage: int = 50
@export var tracking: bool = true  # If true, missile homes in on a target

var target = null

@onready var sprite = $AnimatedSprite2D

func _ready():
	if target and not is_instance_valid(target):
		find_target()
	sprite.play("fly")  # Start flying animation

func _process(delta):
	if tracking and target:
		var direction = (target.global_position - global_position).normalized()
		rotation = rotation + (direction.angle() - rotation) * turn_speed * delta
	
	position += transform.x * speed * delta

func find_target():
	var possible_targets = get_tree().get_nodes_in_group(target_group)
	if possible_targets.size() > 0:
		target = possible_targets[0]  # Simplified, can be improved with closest target logic

func _on_area_entered(area):
	explode()

func explode():
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position

		# Scale up the explosion effect for missiles
		explosion.scale *= 2.0  # Adjust this value to control explosion size

		get_parent().add_child(explosion)

	queue_free()  # Destroy missile
