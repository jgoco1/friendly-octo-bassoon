extends Control

func _ready():
	$StartButton.connect("pressed", Callable(self, "_on_start_pressed"))

func _on_start_pressed():
	GameManager.start_game()
