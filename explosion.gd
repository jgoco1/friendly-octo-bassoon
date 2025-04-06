extends Node2D

@onready var sprite = $ExplodeSprite  # Ensure this matches your node’s name

func _ready():
	if sprite:
		sprite.play("explode")  # Replace "explode" with your actual animation name
		sprite.animation_finished.connect(on_animation_finished)
	else:
		print("Error: ExplodeSprite node not found!")

func on_animation_finished():
	queue_free()  # Removes explosion after animation finishes
