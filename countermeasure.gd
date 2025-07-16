# Countermeasure.gd
extends Node2D

@export var effective_time: float = 3.0  # Duration countermeasure remains active
@export var initial_size: float = 1.5    # Size/scale of the visual
@export var fade_rate: float = 1.0       # Rate at which it fades (alpha reduction)

var elapsed_time: float = 0.0
@onready var sprite = $Sprite2D  # Adjust if you use a different node
@onready var timer = $Timer

func _ready():
	sprite.scale = Vector2(initial_size, initial_size)
	#sprite.modulate = Color(1, 1, 1, 1)  # Full opacity
	timer.wait_time = effective_time
	timer.one_shot = true
	timer.start()
	# Add group dynamically depending on how this instance was created
	# Parent should call `add_to_group()` manually to set it as "player_units" or "enemies"

func _process(delta):
	elapsed_time += delta
	var remaining = clamp(effective_time - elapsed_time, 0, effective_time)
	var alpha = remaining / effective_time
	sprite.modulate.a = alpha  # Smooth fade over time

func _on_Timer_timeout():
	queue_free()
