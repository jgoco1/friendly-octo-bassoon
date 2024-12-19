extends CharacterBody2D

@export var speed = 400
@export var rotation_speed = 0.5
@export var max_bank_angle = 7

var screenSize
var rotation_direction = 0

func get_input():
	if abs(rotation_direction + (Input.get_axis("left", "right") * rotation_speed)) < max_bank_angle: ##Limit max turn
		rotation_direction = rotation_direction + (Input.get_axis("left", "right") * rotation_speed)

	if(abs(rotation_direction) and !Input.get_axis("left","right")) : ##If not steerinng return to center
		if(rotation_direction > 0):
			rotation_direction -= 0.5 * rotation_speed
			rotation_direction = clamp(rotation_direction, 0, max_bank_angle)
		else:
			rotation_direction += 0.5 * rotation_speed
			rotation_direction = clamp(rotation_direction, -max_bank_angle, 0)
	
	velocity = transform.y * Input.get_axis("down", "up") * speed * -1 ##Track forward speed

func _ready():
	screenSize = get_viewport_rect().size

func _physics_process(delta):
	get_input()
	rotation += rotation_direction * delta
	move_and_slide()
	position += velocity * delta
	$AnimatedSprite2D.flip_v = false
	if(velocity) :
		if(rotation_direction > (max_bank_angle / 1.5) ) :
			$AnimatedSprite2D.play("Hard_Bank")
		elif (rotation_direction < -(max_bank_angle / 1.5) ) :
			$AnimatedSprite2D.play("Hard_Bank")
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.play("Forward")
	else:
		$AnimatedSprite2D.play("default")
	
