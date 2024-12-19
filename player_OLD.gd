extends Area2D

@export var speed = 600
var hor_speed = 100
var accel = 25
var hor_accel = 5
var screen_size
var velocity = Vector2.ZERO
float angle = 0
# Called when the node enters the scene tree for the first time.

func calcAngle():
	if Input.is_action_pressed("right"):
		$AnimatedSprite2D.play("turn")
		$AnimatedSprite2D.flip_h = false
		angle = (angle + hor_accel) % 2
	elif Input.is_action_pressed("left"):
		$AnimatedSprite2D.play("turn")
		$AnimatedSprite2D.flip_h = true
		angle = (angle - hor_accel) % 2
	else:
		$AnimatedSprite2D.play("forward")
		$AnimatedSprite2D.flip_h = false
		
		
func calcVelocity():
	if Input.is_action_pressed("down"):
		if(abs(velocity.y + accel) < speed):
			velocity.y += accel
	if Input.is_action_pressed("up"):
		if(abs(velocity.y - accel) < speed):
			velocity.y -= accel
	if Input.is_action_pressed("stop"):
		if velocity.y > 0:
			velocity.y -= accel
		elif velocity.y < 0:
			velocity.y += accel
		if velocity.x > 0:
			velocity.x -= accel
		elif velocity.x < 0:
			velocity.x += accel
			
	return velocity

func _ready():
	screen_size = get_viewport_rect().size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	angle = calcAngle()
	velocity = calcVelocity()
	print(velocity.x, velocity.y)
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	if abs(velocity.x) >= 50:
		$AnimatedSprite2D.play("turn")
		"$AnimatedSprite2D.flip_h = velocity.x < 0"
	elif velocity.y != 0:
		$AnimatedSprite2D.play("forward")
		"$AnimatedSprite2D.flip_v = velocity.y > 0"
	else:
		$AnimatedSprite2D.play("still")
	$AnimatedSprite2D.rotation = velocity.angle()
	"	
	$AnimatedSprite2D.flip_h = velocity.x < 0
	$AnimatedSprite2D.flip_v = velocity.y > 0"
