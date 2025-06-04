extends Node2D

@onready var sprite = $ExplodeSprite  # Ensure this matches your node’s name

func _ready():
	if sprite:
		sprite.rotation = randf_range(0, TAU)  # Random rotation
		#sprite.scale = Vector2(randf_range(0.8, 1.2), randf_range(0.8, 1.2))  # Slight variation in explosion size
		sprite.modulate.a = randf_range(0.7, 1.0)  # Randomized transparency
		sprite.play("explode")
		sprite.animation_finished.connect(on_animation_finished)
	else:
		print("Error: ExplodeSprite node not found!")

func on_animation_finished():
	queue_free()  # Removes explosion after animation finishes
